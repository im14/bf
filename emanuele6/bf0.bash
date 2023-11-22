#!/bin/bash --

set -f
x=$1 i=0 j=0 t=() s=()

# Written as short as possible to fit in a IRC message to shbot with the
# brainfuck code.
# I incorrectly implemented [...] as a do-while instead of while because
# I was misremembering how it worked.
for((;i<${#x};++i))do z=${x:i:1};case $z in +|-)((s[j]$z$z));;.)printf \\x$(printf %x ${s[j]});;\])((s[j]))&&i=${t[-1]}-1;unset t[-1];;\[)t+=($i);;\>)((++j));;\<)((--j))esac done
