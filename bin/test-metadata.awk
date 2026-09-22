#!/usr/bin/gawk -f

# Synopsis:
# Extract per-test metadata from a Unity test file, for version 3 of
# https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Two things are picked up for each test: the body of its test function,
# which is reported as "test_code", and the task it belongs to, which concept
# exercise test files mark with a comment:
#
#     // TASK: 1
#     void test_expected_minutes_in_oven(void) {
#         ...
#     }
#
# A marker applies to every test function that follows it, until the next
# marker. Tests declared before the first marker -- which, in a practice
# exercise, means all of them -- are left unlinked.

# Output:
# One JSON object per RUN_TEST(...) call in main(), in that order:
#
#     {"name":"test_x","test_code":"...","task_id":1}
#
# "test_code" is omitted when the body is empty and "task_id" when the test is
# not linked to a task. A RUN_TEST with no matching definition still yields a
# record carrying just the name, so a result can be attributed to it.

# Run under LC_ALL=C: fields are treated as bytes, whatever the file holds.

BEGIN {
    task = ""
    capturing = 0
    in_comment = 0
    n_run = 0
    for (i = 0; i < 256; i++) BYTE[sprintf("%c", i)] = i
}

function json_string(s,        out, pos, c, code) {
    out = "\""
    for (pos = 1; pos <= length(s); pos++) {
        c = substr(s, pos, 1)
        code = BYTE[c]
        if      (c == "\"" || c == "\\") out = out "\\" c
        else if (c == "\n")              out = out "\\n"
        else if (c == "\r")              out = out "\\r"
        else if (c == "\t")              out = out "\\t"
        else if (code < 32)              out = out sprintf("\\u%04x", code)
        else                             out = out c
    }
    return out "\""
}

# Return the index of the closing quote of the literal opening at `i`.
function skip_literal(line, i, quote,    c) {
    while (i <= length(line)) {
        c = substr(line, i, 1)
        if (c == "\\") i++
        else if (c == quote) return i
        i++
    }
    return i
}

# Advance the brace depth across one line of C, ignoring braces inside
# comments, character literals and string literals. Block comments may span
# lines, so their state outlives the call.
function scan_braces(line, depth,    i, c, next_c) {
    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        next_c = substr(line, i + 1, 1)
        if (in_comment) {
            if (c == "*" && next_c == "/") {
                in_comment = 0
                i++
            }
            continue
        }
        if (c == "/" && next_c == "/") break
        if (c == "/" && next_c == "*") {
            in_comment = 1
            i++
        }
        else if (c == "\"" || c == "'") i = skip_literal(line, i + 1, c)
        else if (c == "{") depth++
        else if (c == "}") depth--
    }
    return depth
}

# Join the captured body lines, stripping the indentation they share and
# any blank lines top and bottom.
function dedent(count,    i, margin, out) {
    margin = -1
    for (i = 1; i <= count; i++) {
        if (body[i] ~ /^[[:space:]]*$/) continue
        match(body[i], /^[[:space:]]*/)
        if (margin < 0 || RLENGTH < margin) margin = RLENGTH
    }
    if (margin < 0) return ""
    for (i = 1; i <= count; i++) out = out (i == 1 ? "" : "\n") substr(body[i], margin + 1)
    sub(/^\n+/, "", out)
    sub(/\n+$/, "", out)
    return out
}

function finish_body() {
    code[name] = dedent(count)
    capturing = 0
    delete body
}

# Inside a test function: keep every line until the brace that closes it.
capturing {
    # The runner blanks these before compiling; drop any that remain so the
    # student never sees a skip directive in their test code.
    if ($0 ~ /^[[:space:]]*TEST_IGNORE\(\);[[:space:]]*$/) next
    depth = scan_braces($0, depth)
    if (depth > 0) body[++count] = $0
    else finish_body()
    next
}

in_comment {
    scan_braces($0, 0)
    next
}

match($0, /^[[:space:]]*\/\/[[:space:]]*TASK:[[:space:]]*([0-9]+)/, marker) {
    task = marker[1]
    next
}

# A test function: remember its task and start collecting its body. The
# opening brace is usually on this line, but is also accepted on a later one.
match($0, /^[[:space:]]*void[[:space:]]+(test_[A-Za-z0-9_]*)[[:space:]]*\([[:space:]]*void[[:space:]]*\)/, decl) {
    name = decl[1]
    if (task != "") task_of[name] = task
    count = 0
    depth = scan_braces($0, 0)
    capturing = 1
    next
}

# main() lists the tests in the order Unity runs them.
/RUN_TEST[[:space:]]*\(/ {
    n = split($0, parts, /RUN_TEST[[:space:]]*\(/)
    for (i = 2; i <= n; i++) {
        if (match(parts[i], /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*/)) {
            id = substr(parts[i], RSTART, RLENGTH)
            sub(/^[[:space:]]+/, "", id)
            run_order[++n_run] = id
        }
    }
    scan_braces($0, 0)
    next
}

{
    scan_braces($0, 0)
}

END {
    for (i = 1; i <= n_run; i++) {
        id = run_order[i]
        out = "{\"name\":" json_string(id)
        if ((id in code) && code[id] != "")
            out = out ",\"test_code\":" json_string(code[id])
        if (id in task_of)
            out = out ",\"task_id\":" task_of[id]
        print out "}"
    }
}
