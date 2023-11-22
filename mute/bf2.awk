#!/usr/bin/mawk -f
# 2023-11-21 mute <scott@nicholas.one>
BEGIN {
  RS=""
  ti=-1
  t[++ti]=0
  if (opts == "") opts="CR"
}

function compile(   ii, ci, z, nz) {
  if (debug) {
    printf("Running optimizations (%s)...", opts)
    fflush()
  }
  # strip comments
  gsub(/[^][<>,.+-]/, "")


  ii = length($0)
  ci = 0
  for (i = 1; i <= ii; i++) {
    z = substr($0, i, 1)
    zc = 1

    # Clear operator
    if (opts ~ /[Cc]/ && z == "[") {
      pat = substr($0, i, 3)
      if (pat == "[-]" || pat == "[+]") {
        code[ci++] = "C"
        code[ci++] = 0
        i += 2
        continue
      }
    }
    # RLE, run length encoding, or contraction
    if (opts ~ /[Rr]/) {
      while (z ~ /[<>+-]/ && i < ii) {
        nz = substr($0, ++i, 1)
        if (nz == z) zc++
        else {
          i--
          break
        }
      }
    }

    code[ci++] = z
    code[ci++] = zc
  }
  if (debug) {
    printf("done.\nbrainfuck string=%d, intermediate code ops=%d %d%%\n%04d", length($0), ci / 2, 100*ci / (2 * length($0)), 0)
    for (i = 0; i < ci; i += 2) {
      printf (" %s%02d%s", code[i], code[i + 1], (2 + i) % 32 ? "" : ("\n" sprintf("%04d", i)))
    }
    printf("\n")
  }
}

function run() {
  ii = length(code)
  s[0] = 0
  j = 1
  for (i = 0; i < ii; i += 2) {
    z  = code[i]
    zc = code[i+1]

    if (t[ti] < 0 && z !~ /[][]/) continue

    if (z == ".") {
      printf("%c", s[j])
      fflush()
    } else if (z == "+") {
      s[j] += zc
      while (s[j] > 255) s[j] -= 256
    } else if (z == "-") {
      s[j] -= zc
      while (s[j] < 0) s[j] += 256
    } else if (z == "]") {
      if (s[j] > 0) i = t[ti] - 2
      delete t[ti--]
    } else if (z == "[") {
      t[++ti] = s[j] ? i : -1
    } else if (z == ">") {
      j += zc
    } else if (z == "<") {
      j -= zc
    } else if (z == "C") {
      s[j] = 0
    }
  }
  printf("\n")
}

{
  compile($0)
  run()
}
