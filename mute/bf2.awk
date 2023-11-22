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
  split("", stack)
  stackidx = 1
  tape[tapeidx++] = 0

  for (i = 0; i < codelen; i += 2) {
    op    = code[i]
    oparg = code[i + 1]

    if (tape[tapeidx] < 0 && op !~ /[][]/) continue

    if (op == ".") {
      printf("%c", stack[stackidx])
      fflush()
    } else if (op == "+") {
      stack[stackidx] += oparg
      while (stack[stackidx] > 255) stack[stackidx] -= 256
    } else if (op == "-") {
      stack[stackidx] -= oparg
      while (stack[stackidx] < 0) stack[stackidx] += 256
    } else if (op == "]") {
      if (stack[stackidx] > 0) i = tape[tapeidx] - 2
      delete tape[tapeidx--]
    } else if (op == "[") {
      tape[++tapeidx] = stack[stackidx] ? i : -1
      for (ti = 0; ti <= tapeidx; ti++)
    } else if (op == ">") {
      stackidx += oparg
    } else if (op == "<") {
      stackidx -= oparg
    } else if (op == "C") {
      stack[stackidx] = 0
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
