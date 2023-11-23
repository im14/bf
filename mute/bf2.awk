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

function compile(bfstr, prog, jump,    bflen, pc, i, op, oparg, stack, si)
{
  if (debug) {
    printf("Running optimizations (%s)...", opts)
    fflush(stdout)
  }
  # strip comments
  gsub(/[^\]\[<>,.+\-]/, "", bfstr)

  bflen = length(bfstr)
  pc = 0
  for (i = 1; i <= bflen; i++) {
    op = substr(bfstr, i, 1)
    oparg = 1

    # Clear operator
    if (op == "[" && opts ~ /[Cc]/ && match(substr(bfstr, i), /^\[[-+]\]/)) {
      prog[pc++] = "C"
      prog[pc++] = 0
      i += 2
      continue
    }
    # Scan loops
    if (op == "[" && opts ~ /[Ss]/ && match(substr(bfstr, i), /^\[[<>]+]/)) {
      prog[pc++] = "S"
      prog[pc++] = (substr(bfstr, 1 + i, 1) == "<" ? -1 : 1) * (RLENGTH - 2)
      i += RLENGTH - 1
      continue
    }
    # RLE, run length encoding, or contraction
    if (opts ~ /[Rr]/) {
      while (op ~ /[<>+-]/ && i <= bflen) {
        if (op == substr(bfstr, ++i, 1)) oparg++
        else {
          i--
          break
        }
      }
    }

    # pre-compute jump table
    if (op == "[")
      stack[si++] = pc
    else if (op == "]")
      jump[jump[pc] = stack[--si]] = pc

    prog[pc++] = op
    prog[pc++] = oparg
  }
  if (debug) {
    printf("done.\nbrainfuck string=%d, intermediate code ops=%d %d%%\n%04d",
           bflen, pc / 2, 100 * pc / (2 * bflen), 0)
    for (i = 0; i < pc; i += 2) {
      printf(" %s%02d%s", prog[i], prog[i + 1],
             (2 + i) % 32 ? "" : ("\n" sprintf("%04d", i)))
    }
    printf("\n")
    if (debug == 2) exit
  }
  return pc
}

function run(prog, jump, proglen,    op, oparg, pc, tape, cell)
{
  split("", tape)
  cell = 1

  for (pc = 0; pc < proglen; pc += 2) {
    op    = prog[pc]
    oparg = prog[pc + 1]

         if (op == ".") { printf("%c", tape[cell]); fflush(stdout) }
    else if (op == ">") { cell += oparg }
    else if (op == "<") { cell -= oparg }
    else if (op == "+") { tape[cell] += oparg; while (tape[cell] > 255) tape[cell] -= 256 }
    else if (op == "-") { tape[cell] -= oparg; while (tape[cell] <   0) tape[cell] += 256 }
    else if (op == "[") { if (!tape[cell]) pc = jump[pc] }
    else if (op == "]") { if ( tape[cell]) pc = jump[pc] }
    else if (op == "C") { tape[cell] = 0 }
    else if (op == "S") { while (tape[cell]) cell += oparg }
  }
  printf("\n")
}

{
  bfstr = bfstr $0
}

END {
  split("", prog)
  split("", jump)
  proglen = compile(bfstr, prog, jump)
  run(prog, jump, proglen)
}
