#!/bin/sh
# \
exec jq --args --unbuffered -nsjRf "$0" -- "$@"

$ARGS.positional[] // inputs |

[
    scan("[+-]+|\\[-\\]|[][.]|[<>]+") |

    if . == "[-]" then
        { op: "set", value: 0 }
    elif .[0:1] | IN("+", "-") then
        reduce scan(".") as $op (0;
            . + if $op == "+" then 1 else -1 end) |
        { op: "add", value: select(. != 0) }
    elif .[0:1] | IN("<", ">") then
        reduce scan(".") as $op (0;
            . + if $op == ">" then 1 else -1 end) |
        { op: "shift", value: select(. != 0) }
    elif . == "." then
        { op: "print", value: null }
    else . end
] |

{ blocks: [], starts: [], code: . } |
reduce (.code | to_entries[]) as { $key, $value } (.;
    if $value == "[" then
        .starts += [ $key ]
    elif $value == "]" then
        if .starts == [] then
            "Invalid code: Unexpected ]\n" |
            halt_error(2)
        else . end |
        def offset: .starts[-1];
        .code[$key] = { op: "jnz", value: (offset + 1) } |
        .blocks += [ [ offset, $key ] ] |
        del(offset)
    else . end) |

reduce .blocks[] as [ $start, $end ] (.code;
    .[$start] = { op: "jz", value: ($end + 1) }) |

{ out: null, offset: 0, shift: 0, vals: {}, code: . } |
while(.offset < (.code | length);
    .out = null |
    .code[.offset] as { $op, $value } |
    def val: .vals[.shift | tostring];
    if $op == "jz" then
        select(val == 0).offset |= $value - 1
    elif $op == "jnz" then
        select(val != 0).offset |= $value - 1
    elif $op == "add" then
        val |= (. + $value) % 256
    elif $op == "shift" then
        .shift += $value |
        val //= 0
    elif $op == "set" then
        val = $value
    elif $op == "print" then
        .out = val
    else . end |
    .offset += 1).out |
values |
[ . ] |
implode
