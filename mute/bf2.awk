#!/usr/bin/mawk -f
# 2023-11-21 mute <scott@nicholas.one>
# tested in gawk, mawk, bawk (brian's true awk), 9awk. mawk is best.
BEGIN {
  # Plan 9 awk detection. But /dev/stdout probably only in Linux.
  if ("]" ~ /[^][]/) {
    stdout = "/dev/stdout"
  }
  if (opts == "") opts = "CRSZ"
}

function translate(prog, proglen, outcmd,   depth, i, op, oparg)
{
  depth = 1
  out = sprintf("\n\nBEGIN {\n  cell = 1\n")
  for (i = 0; i < proglen; i += 2) {
    op = prog[i]
    oparg = prog[1+i]
    if (op == "]") depth--
    out = out sprintf("%*s", 2 * depth, "")
         if (op == ".") { out = out sprintf("printf(\"%%c\", tape[cell]); fflush(stdout)\n") }
    else if (op == ">") { out = out sprintf("cell += %d\n", oparg) }
    else if (op == "<") { out = out sprintf("cell -= %d\n", oparg) }
    else if (op == "+") { out = out sprintf("tape[cell] += %d\n", oparg) }
    else if (op == "-") { out = out sprintf("tape[cell] -= %d\n", oparg) }
    else if (op == "[") { out = out sprintf("while (tape[cell]) {\n"); depth++ }
    else if (op == "]") { out = out sprintf("}\n") }
    else if (op == "Z") { out = out sprintf("tape[cell] = 0\n") }
    else if (op == "S") { out = out sprintf("while (tape[cell]) cell += %d\n", oparg) }
    else if (op == "C") { out = out sprintf("tape[cell+%d] += tape[cell]; tape[cell] = 0\n", oparg) }
  }
  out = out sprintf("  print nl\n}\n")
  if (outcmd)
    printf("%s", out) | outcmd
  else
    printf("%s", out)
}

function compile(bfstr, prog, jump,    bflen, pc, i, op, oparg, stack, si)
{
  if (verbose) {
    printf("Running optimizations (%s)... %d", opts, length(bfstr))
    fflush(stdout)
  }
  # strip comments
  gsub(/[^\]\[<>,.+\-]/, "", bfstr)

  # first pass
  bflen = length(bfstr)
  if (verbose) printf(" %d", bflen)
  pc = 0
  for (i = 1; i <= bflen; i++) {
    op = substr(bfstr, i, 1)
    oparg = 1

    # Zero operator
    if (op == "[" && opts ~ /[Zz]/ && match(substr(bfstr, i), /^\[[-+]\]/)) {
      prog1[pc++] = "Z"
      prog1[pc++] = 0
      i += 2
      continue
    }
    # Scan loops
    if (op == "[" && opts ~ /[Ss]/ && match(substr(bfstr, i), /^\[[<>]+]/)) {
      prog1[pc++] = "S"
      prog1[pc++] = (substr(bfstr, 1 + i, 1) == "<" ? -1 : 1) * (RLENGTH - 2)
      i += RLENGTH - 1
      continue
    }
    # Copy
    if (op == "[" && opts ~ /[Cc]/ && match(substr(bfstr, i), /^\[->+\+<+]/)) {
      x = (RLENGTH - 4) / 2
      prog1[pc++] = "C"
      prog1[pc++] = x
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

    prog1[pc++] = op
    prog1[pc++] = oparg
  }
  if (verbose) printf(" %d", pc / 2)

  # second pass (currently not used)
  origpc = pc
  pc = 0
  for (i = 0; i < origpc; i += 2) {
    # pre-compute jump table
    if (prog1[i] == "[")
      stack[si++] = pc
    else if (prog1[i] == "]")
      jump[jump[pc] = stack[--si]] = pc
    prog[pc++] = prog1[i]
    prog[pc++] = prog1[1 + i]
  }

  if (verbose)
    printf(" %d. %d%% original (without comments)\n",
           pc / 2, 100 * pc / (2 * bflen))
  return pc
}

function interpret(prog, jump, proglen,    op, oparg, pc, tape, cell)
{
  split("", tape)
  cell = 1

  for (pc = 0; pc < proglen; pc += 2) {
    op    = prog[pc]
    oparg = prog[pc + 1]

         if (op == ".") { printf("%c", tape[cell]); fflush(stdout) }
    else if (op == ">") { cell += oparg }
    else if (op == "<") { cell -= oparg }
    else if (op == "+") { tape[cell] += oparg; }
    else if (op == "-") { tape[cell] -= oparg; }
    else if (op == "[") { if (!tape[cell]) pc = jump[pc] }
    else if (op == "]") { if ( tape[cell]) pc = jump[pc] }
    else if (op == "Z") { tape[cell] = 0 }
    else if (op == "S") { while (tape[cell]) cell += oparg }
    else if (op == "C") { tape[cell+oparg] += tape[cell]; tape[cell] = 0; }
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
  if (mode ~ /p/) # print only
    translate(prog, proglen)
  else if (mode ~ /t/) # translate
    translate(prog, proglen, "mawk -f -")
  else if (mode !~ /e/) # interpret
    interpret(prog, jump, proglen)
}
