#!/usr/bin/tclsh
# a brainfuck in tclsh. mute (m@san.aq) 19nov2015
# vim:ts=2:sw=2:sts=2:et:

proc bf {code} { 
  set p 0
  set c 0
  set tape(0) 0
  lappend stack 0

  for {set c 0} {$c < [string length $code]} {incr c 1} {
    set op [string index $code $c]
    if {[lindex $stack end] < 0 && ! [regexp {[][]} $op]} {
      continue
    }
    switch -- $op {
      {>} { incr p }
      {<} { incr p -1 }
      {+} { if {[info exist tape($p)] == 0} {set tape($p) 0}; set tape($p) [expr {($tape($p)+1)&255}] }
      {-} { if {[info exist tape($p)] == 0} {set tape($p) 0}; set tape($p) [expr {($tape($p)-1)&255}] }
      {[} {
        if {[info exist tape($p)] == 0} {set tape($p) 0}
        if {$tape($p) > 0} {
          lappend stack $c
        } else {
          lappend stack -1
        }
      }
      {]} {
        if {[info exist tape($p)] == 0} {set tape($p) 0}
        if {$tape($p) > 0} {
          set c [lindex $stack end]
          incr c -1
        }
        set stack [lreplace $stack end end]
      }
      {.} {
        if {[info exist tape($p)] == 0} {set tape($p) 0}
        puts -nonewline [format "%c" $tape($p)]
        flush stdout
      }
    }
  }
  if {$c > 0} {puts ""} ;#newline hax
}

set file [open [lindex $argv 0] r]

bf [read $file]
#foreach line [split [read $file] "\n"] {
#	bf $line
#}

close $file
