#!/usr/bin/tclsh
# a brainfuck in tclsh. mute (m@san.aq) 19nov2015
# vim:ts=2:sw=2:sts=2:et:

proc bf {program} {
  set p 0
  set c 0
  set code "set p 0\n"

  for {set c 0} {$c < [string length $program]} {incr c} {
    switch -- [string index $program $c] {
      {>} {
        for {set i 1} {[string index $program [incr c]] == ">"} {incr i} {}
        incr c -1
        append code "incr p $i\n"
        append code "if {\[info exist tape(\$p)] == 0} {set tape(\$p) 0}\n"
      }
      {<} {
        for {set i 1} {[string index $program [incr c]] == "<"} {incr i} {}
        incr c -1
        append code "incr p -$i\n"
        append code "if {\[info exist tape(\$p)] == 0} {set tape(\$p) 0}\n"
      }
      {+} {
        for {set i 1} {[string index $program [incr c]] == "+"} {incr i} {}
        incr c -1
#        append code "set tape(\$p) \[expr {(\[info exist tape(\$p)]?\$tape(\$p):0)+$i&255}]\n"
        append code "incr tape(\$p) $i\nset tape(\$p) \[expr {\$tape(\$p)&255}]\n"
      }
      {-} {
        for {set i 1} {[string index $program [incr c]] == "-"} {incr i} {}
        incr c -1
#        append code "set tape(\$p) \[expr {(\[info exist tape(\$p)]?\$tape(\$p):0)-$i&255}]\n"
        append code "incr tape(\$p) -$i\nset tape(\$p) \[expr {\$tape(\$p)&255}]\n"
      }
      {[} {
        append code "while {\$tape(\$p) > 0} \{\n"
      }
      {]} {
        append code "\}\n" 
      }
      {.} {
        append code {puts -nonewline [format "%c" $tape($p)];flush stdout}
        append code "\n"
      }
    }
  }
  if {$c > 0} {
    if 1 $code
    puts ""
  }
}

set file [open [lindex $argv 0] r]

bf [read $file]
#foreach line [split [read $file] "\n"] {
#	bf $line
#}

close $file
