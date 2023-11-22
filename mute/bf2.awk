#!/usr/bin/mawk -f
# 2023-11-21 mute <scott@nicholas.one>
BEGIN {
  RS = ""
  if (opts == "") opts = "CR"
}

function compile(bfstr, code,    bflen, codeidx, codelen, i, nextop, op, oparg,
                 pat)
{
  if (debug) {
    printf("Running optimizations (%s)...", opts)
    fflush()
  }
  # strip comments
  gsub(/[^][<>,.+-]/, "", bfstr)


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

    if (stack[stackidx] < 0 && op !~ /[][]/) continue

    if (op == ".") {
      printf("%c", tape[tapeidx])
      fflush()
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
    }
  }
  printf("\n")
}

# with RS="" everything should be one line
# main()
{
  split("", code)
  codelen = compile($0, code)
  run(code, codelen)
}
