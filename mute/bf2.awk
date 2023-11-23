#!/usr/bin/mawk -f
# 2023-11-21 mute <scott@nicholas.one>
# tested in gawk, mawk, bawk (brian's true awk), 9awk. mawk is best.
BEGIN {
  # Plan 9 awk detection. But /dev/stdout probably only in Linux.
  if ("]" ~ /[^][]/) {
    stdout = "/dev/stdout"
  }
  if (opts == "") opts = "CSR"
}

function compile(bfstr, code,    bflen, codeidx, codelen, i, nextop, op, oparg,
                 pat)
{
  if (debug) {
    printf("Running optimizations (%s)...", opts)
    fflush(stdout)
  }
  # strip comments
  gsub(/[^\]\[<>,.+\-]/, "", bfstr)

  bflen = length(bfstr)
  codeidx = 0
  for (i = 1; i <= bflen; i++) {
    op = substr(bfstr, i, 1)
    oparg = 1

    # Clear operator
    if (opts ~ /[Cc]/ && op == "[") {
      pat = substr(bfstr, i, 3)
      if (pat == "[-]" || pat == "[+]") {
        code[codeidx++] = "C"
        code[codeidx++] = 0
        i += 2
        continue
      }
    }
    # Scan loops
    if (opts ~ /[Ss]/ && op == "[") {
      if (match(substr(bfstr, i), /^\[>+]/)) {
        code[codeidx++] = "S"
        code[codeidx++] = RLENGTH - 2
        i += RLENGTH - 1
        continue
      } else if (match(substr(bfstr, i), /^\[<+]/)) {
        code[codeidx++] = "S"
        code[codeidx++] = -1 * (RLENGTH - 2)
        i += RLENGTH - 1
        continue
      }
    }
    # RLE, run length encoding, or contraction
    if (opts ~ /[Rr]/) {
      while (op ~ /[<>+-]/ && i <= bflen) {
        nextop = substr(bfstr, ++i, 1)
        if (nextop == op) oparg++
        else {
          i--
          break
        }
      }
    }

    code[codeidx++] = op
    code[codeidx++] = oparg
  }
  if (debug) {
    printf("done.\nbrainfuck string=%d, intermediate code ops=%d %d%%\n%04d",
           bflen, codeidx / 2, 100 * codeidx / (2 * bflen), 0)
    for (i = 0; i < codeidx; i += 2) {
      printf(" %s%02d%s", code[i], code[i + 1],
             (2 + i) % 32 ? "" : ("\n" sprintf("%04d", i)))
    }
    printf("\n")
    if (debug == 2) exit
  }
  return codeidx
}

function run(code, codelen,    i, op, oparg, stack, stackidx, tape, tapeidx)
{
  split("", tape)
  tapeidx = 1
  stack[stackidx++] = 0

  for (i = 0; i < codelen; i += 2) {
    op    = code[i]
    oparg = code[i + 1]

    if (stack[stackidx] < 0 && op !~ /[\]\[]/) continue
    if (op == ".") {
      printf("%c", tape[tapeidx])
      fflush(stdout)
    } else if (op == "+") {
      tape[tapeidx] += oparg
      while (tape[tapeidx] > 255) tape[tapeidx] -= 256
    } else if (op == "-") {
      tape[tapeidx] -= oparg
      while (tape[tapeidx] < 0) tape[tapeidx] += 256
    } else if (op == "]") {
      if (tape[tapeidx] > 0) i = stack[stackidx] - 2
      delete stack[stackidx--]
    } else if (op == "[") {
      stack[++stackidx] = tape[tapeidx] ? i : -1
    } else if (op == ">") {
      tapeidx += oparg
    } else if (op == "<") {
      tapeidx -= oparg
    } else if (op == "C") {
      tape[tapeidx] = 0
    } else if (op == "S") {
      while (tape[tapeidx]) tapeidx += oparg
    }
  }
  printf("\n")
}

{
  bfstr = bfstr $0
}

END {
  split("", code)
  codelen = compile(bfstr, code)
  run(code, codelen)
}
