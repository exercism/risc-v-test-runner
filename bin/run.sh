#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output
# directory. The test results are formatted according to the specifications at
# https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer path/to/solution/folder/ path/to/output/directory/

set -uo pipefail

# The platform reads results.json as an unprivileged user; this script runs
# as root in the container. Nothing here may create root-only files.
umask 022

# Byte semantics for gawk and stable behaviour everywhere else, whatever
# bytes the solution decides to print.
export LC_ALL=C

# Wall-clock limits, in seconds. The platform allows 20 seconds in total.
: "${COMPILE_TIMEOUT:=15}"
: "${RUN_TIMEOUT:=10}"

# Cap on the message field of results.json.
: "${MAX_MESSAGE_BYTES:=65536}"

# Cap on any single file the test program writes, enforced with ulimit so a
# print loop hits a limit rather than filling /tmp.
: "${MAX_OUTPUT_BYTES:=8388608}"

runner_dir=$(dirname "$(realpath "$0")")
test_metadata="${runner_dir}/test-metadata.awk"
unity_to_json="${runner_dir}/unity-to-json.awk"

usage() {
    echo "usage: $0 exercise-slug path/to/solution/folder/ path/to/output/directory/" >&2
    exit 1
}

[[ -z "${1:-}" || -z "${2:-}" || -z "${3:-}" ]] && usage

slug="$1"
solution_dir=$(realpath "${2%/}")
output_dir=$(realpath "${3%/}")

[[ -d "${solution_dir}" ]] || usage
mkdir -p "${output_dir}"

results_file="${output_dir}/results.json"
snake_slug="${slug//-/_}"

# Assigned before use so the trap can always expand it.
work_dir=""
trap 'rm -rf "${work_dir}"' EXIT

# A fault in the runner itself is still reported through results.json when
# possible: an empty output directory tells the platform nothing.
die() {
    echo "$*" >&2
    if [[ -n "${work_dir}" ]]; then
        printf '%s\n' "$*" > "${work_dir}/died"
        finish_with error "${work_dir}/died"
    fi
    exit 1
}

# capped <file>: copy at most MAX_MESSAGE_BYTES of a capture to stdout,
# noting the cut. Callers redirect this into a file, which is what jq's
# --rawfile reads to build the message.
capped() {
    local file="$1"
    head -c "${MAX_MESSAGE_BYTES}" "${file}"
    if (( $(wc -c < "${file}") > MAX_MESSAGE_BYTES )); then
        printf '\n[output truncated]'
    fi
}

# finish_with <pass|fail|error> <message-file>: results.json without
# per-test entries, for everything that stops before tests can be reported.
finish_with() {
    local status="$1" message_file="$2"
    if ! grep -q '[^[:space:]]' "${message_file}" 2>/dev/null; then
        printf 'the test run produced no output\n' > "${message_file}"
    fi
    capped "${message_file}" > "${message_file}.capped"
    jq -n --arg status "${status}" --rawfile message "${message_file}.capped" \
        '{version: 3, status: $status,
          message: ($message | sub("^\n+"; "") | rtrimstr("\n"))}' \
        > "${results_file}"
    echo "${slug}: done"
}

# zig keeps the musl libc and compiler_rt it builds for the target in its
# global cache, which the Dockerfile fills at build time. zig writes a
# manifest there even when every artifact is a cache hit, and the production
# container is read-only, so a copy under /tmp takes over when the baked
# cache cannot be written to. cp -a preserves mtimes: the copy stays a hit.
# The local cache holds this one compilation and always lives in /tmp.
prepare_zig_cache() {
    local probe
    if [[ -n "${ZIG_GLOBAL_CACHE_DIR:-}" ]]; then
        if probe=$(mktemp "${ZIG_GLOBAL_CACHE_DIR}/.write-probe.XXXXXX" 2>/dev/null); then
            rm -f "${probe}"
        else
            cp -a "${ZIG_GLOBAL_CACHE_DIR}" "${work_dir}/zig-global" \
                || die "cannot copy the zig cache"
            export ZIG_GLOBAL_CACHE_DIR="${work_dir}/zig-global"
        fi
    fi
    export ZIG_LOCAL_CACHE_DIR="${work_dir}/zig-local"
}

# The compiled program and its build products go next to the sources, and a
# student's solution directory is not ours to build in, so stage a copy.
stage_solution() {
    local build_dir="${work_dir}/build"
    mkdir "${build_dir}" || die "cannot create the build directory"
    cp -r "${solution_dir}/." "${build_dir}" || die "cannot stage the solution"
    cd "${build_dir}" || die "cannot enter the build directory"
}

# The test file is normally named after the slug. Fall back to any *_test.c
# so a hand-assembled solution still works. Prints the name, or nothing.
find_test_file() {
    local candidate
    if [[ -f "${snake_slug}_test.c" ]]; then
        echo "${snake_slug}_test.c"
        return
    fi
    for candidate in *_test.c; do
        [[ -f "${candidate}" ]] || continue
        echo "${candidate}"
        return
    done
}

# Compile with the exercise's own Makefile. Prints nothing; returns 0 when
# the test program exists afterwards. The compiler output is left in the
# work directory for the error report.
compile_tests() {
    local build_dir="${PWD}"
    # Drop whatever a local build left behind; the Makefile's wildcards would
    # otherwise link stale objects.
    make -s clean > /dev/null 2>&1
    timeout "${COMPILE_TIMEOUT}" make -s tests > "${work_dir}/compile" 2>&1
    local status=$?
    # coreutils timeout exits 124; busybox reports the signal it sent.
    if (( status == 124 || status > 128 )); then
        printf '\ncompilation timed out after %s seconds\n' "${COMPILE_TIMEOUT}" \
            >> "${work_dir}/compile"
    fi
    # Diagnostics name files relative to the build directory already; strip
    # the directory from anything that does not.
    sed -i "s#${build_dir}/##g" "${work_dir}/compile"
    [[ -x ./tests ]]
}

# Run the test program under qemu, capturing everything it and qemu print.
# qemu says nothing when the guest dies by a signal, so the reason the run
# stopped is worked out from the exit status and written to a file for the
# report. A guest that hits the time limit is killed by timeout, whose exit
# status names the signal it sent rather than the timeout, hence the clock.
# A crashing guest would leave a core file; none is wanted.
run_tests() {
    local started="${SECONDS}" status signal
    (
        ulimit -c 0
        ulimit -f $(( MAX_OUTPUT_BYTES / 512 )) 2>/dev/null
        timeout -k 1 "${RUN_TIMEOUT}" qemu-riscv32 ./tests > "${work_dir}/run" 2>&1
    ) 2>/dev/null
    status=$?
    : > "${work_dir}/stopped"
    if (( status == 124 || (status > 128 && SECONDS - started >= RUN_TIMEOUT) )); then
        printf 'The tests timed out after %s seconds' "${RUN_TIMEOUT}" > "${work_dir}/stopped"
    elif (( status > 128 )); then
        signal=$(( status - 128 ))
        printf 'The test program was killed by signal %s (SIG%s)' \
            "${signal}" "$(kill -l "${signal}" 2>/dev/null)" > "${work_dir}/stopped"
    fi
}

# Write results.json from the per-test records, the metadata read from the
# test file, the summary, and the reason the run stopped, if it did.
# Metadata is a left-join by test name, so a test with no definition in the
# file keeps its result and simply gains no "test_code" or "task_id". Key
# order per test: name, test_code, status, message, output, task_id.
#
# When the program stopped before the trailer, the test that was running is
# the first one in RUN_TEST order without a result: it is reported as an
# error carrying whatever was printed after the last result, and the tests
# after it are left out.
write_results() {
    jq -n --slurpfile tests "${work_dir}/tests.jsonl" \
          --slurpfile meta "${work_dir}/meta.jsonl" \
          --slurpfile summary "${work_dir}/summary" \
          --rawfile reason "${work_dir}/stopped" '
        def notice: "\nOutput was truncated. Please limit to 500 chars.";
        def trunc: if length > 500 then .[:500 - (notice | length)] + notice else . end;
        def with_metadata($m):
            {name}
            + (if ($m.test_code // "") != "" then {test_code: $m.test_code} else {} end)
            + del(.name)
            + (if $m.task_id then {task_id: $m.task_id} else {} end);
        def stopped_test($s; $next):
            {name: $next.name, status: "error",
             message: ([($s.trailing | select(. != "")),
                        (if $reason == "" then "The test program stopped" else $reason end)
                        + " while running this test; later tests did not run."]
                       | join("\n"))};

        $summary[0] as $s
        | ($tests | length) as $n
        | ($tests
           | if $s.finished or ($meta | length) <= $n then .
             else . + [stopped_test($s; $meta[$n])] end) as $all
        | ($meta | INDEX(.name)) as $by_name
        | {version: 3,
           status: (if all($all[]; .status == "pass") then "pass" else "fail" end),
           tests: ($all | map(
               (if .output then .output |= trunc else . end)
               | with_metadata($by_name[.name] // {})))}
    ' > "${results_file}" || die "cannot encode the test results"
    echo "${slug}: done"
}

main() {
    [[ -f "${test_metadata}" ]] || die "missing ${test_metadata}"
    [[ -f "${unity_to_json}" ]] || die "missing ${unity_to_json}"
    work_dir=$(mktemp -d) || die "cannot create a work directory"

    echo "${slug}: testing..."

    prepare_zig_cache
    stage_solution

    local test_file
    test_file=$(find_test_file)
    if [[ -z "${test_file}" ]]; then
        printf 'no test file found (expected %s_test.c)\n' "${snake_slug}" \
            > "${work_dir}/message"
        finish_with error "${work_dir}/message"
        return 0
    fi

    # Every test after the first ships skipped, so the student can work
    # through them one at a time. Blank the skips rather than deleting the
    # lines: the line numbers Unity reports then still match the file.
    sed -i 's/^[[:space:]]*TEST_IGNORE();[[:space:]]*$//' "${test_file}"

    if ! compile_tests; then
        finish_with error "${work_dir}/compile"
        return 0
    fi

    run_tests

    gawk -f "${test_metadata}" "${test_file}" > "${work_dir}/meta.jsonl"
    gawk -v SUMMARY="${work_dir}/summary" -f "${unity_to_json}" \
        < "${work_dir}/run" > "${work_dir}/tests.jsonl"

    # No test concluded and the suite never finished: the program died before
    # its first result, and all there is to show is what it printed and why
    # it stopped.
    if [[ ! -s "${work_dir}/tests.jsonl" ]] \
        && ! jq -e '.finished' "${work_dir}/summary" > /dev/null; then
        cat "${work_dir}/run" "${work_dir}/stopped" > "${work_dir}/message"
        finish_with error "${work_dir}/message"
        return 0
    fi

    write_results
}

main "$@"
