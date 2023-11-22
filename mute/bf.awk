#!/bin/awk -f
# simply took emanuele6's short sh version and tried make it 1:1 to awk
BEGIN {
  RS=""
  ti=-1
  t[++ti]=0
}
{
  ii = length($0)
  s[0] = 0
  j = 1
  for (i = 1; i <= ii; i++) {
    z = substr($0, i, 1)
    if (t[ti]<0 && z !~ /[][]/) {
      z = ""
    }
    
    if (z == ".") {
      printf("%c", s[j])
      fflush()
    } else if (z == "+") {
      if (s[j] == 255) s[j] = 0
      else s[j]++
    } else if (z == "-") {
      if (s[j] == 0) s[j] = 255
      else s[j]--
    } else if (z == "]") {
      if (s[j] > 0) i = t[ti] - 1
      delete t[ti--]
    } else if (z == "[") {
      t[++ti] = s[j] ? i :-1
    } else if (z == ">") {
      j++
    } else if (z == "<") {
      j--
    }
  }
  printf("\n")
}

