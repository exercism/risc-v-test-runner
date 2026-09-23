#!/usr/bin/gawk -f

# Synopsis:
# Convert the output of a Unity test program into JSON, one object per test.

# Unity prints one line when each test concludes:
#
#     <file>:<line>:<name>:PASS
#     <file>:<line>:<name>:FAIL: <message>
#     <file>:<line>:<name>:IGNORE[: <message>]
#
# and, once the whole suite has run, a trailer:
#
#     -----------------------
#     <N> Tests <F> Failures <I> Ignored
#     OK | FAIL
#
# Every other line was printed by the solution, or by qemu when the program
# died. Lines printed before a test's result line are that test's "output".

# Reads the captured stdout and stderr on stdin. Writes one JSON object per
# concluded test to stdout, for jq --slurpfile. When SUMMARY names a file,
# also writes {"finished":B,"trailing":"..."} there: whether the trailer
# was seen, and what was printed after the last result when it was not, so
# the caller can report the test that was running when the program stopped.

# Run under LC_ALL=C: fields are treated as bytes, whatever the solution
# printed.

BEGIN {
    SUMMARY = SUMMARY ""    # initialise without disturbing a -v value
    finished = 0
    buffer = ""
    for (i = 0; i < 256; i++) BYTE[sprintf("%c", i)] = i
}

function json_string(s,        out, pos, c, code) {
    out = "\""
    for (pos = 1; pos <= length(s); pos++) {
        c = substr(s, pos, 1)
        code = BYTE[c]
        if      (c == "\"" || c == "\\")    out = out "\\" c
        else if (c == "\n")                 out = out "\\n"
        else if (c == "\r")                 out = out "\\r"
        else if (c == "\t")                 out = out "\\t"
        else if (code < 32 || code == 127)  out = out sprintf("\\u%04x", code)
        else                                out = out c
    }
    return out "\""
}

# Trailing newlines carry no information; the rest is kept as printed.
function trimmed(s) {
    sub(/\n+$/, "", s)
    return s
}

finished { next }

/^[0-9]+ Tests [0-9]+ Failures [0-9]+ Ignored/ {
    finished = 1
    next
}

/^[^:]+:[0-9]+:[A-Za-z_][A-Za-z0-9_]*:(PASS|FAIL|IGNORE)(:.*)?$/ {
    n = split($0, field, ":")
    name = field[3]
    status = field[4]
    # The message follows "FAIL:" or "IGNORE:", and may itself contain colons.
    message = field[5]
    for (i = 6; i <= n; i++) message = message ":" field[i]
    sub(/^ /, "", message)

    out = "{\"name\":" json_string(name)
    if (status == "PASS") {
        out = out ",\"status\":\"pass\""
    } else {
        out = out ",\"status\":\"fail\""
        if (status == "IGNORE") message = "test ignored" (message == "" ? "" : ": " message)
        if (message != "") out = out ",\"message\":" json_string(message)
    }
    if (buffer != "") out = out ",\"output\":" json_string(trimmed(buffer))
    print out "}"
    buffer = ""
    next
}

{ buffer = buffer $0 "\n" }

END {
    if (SUMMARY != "")
        printf "{\"finished\":%s,\"trailing\":%s}\n", \
               (finished ? "true" : "false"), json_string(trimmed(buffer)) > SUMMARY
}
