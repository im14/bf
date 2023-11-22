#!/bin/bash --

x=$1 i=0 j=0 t=() s=()

# Written as short as possible to fit in a IRC message to shbot with the
# brainfuck code.
for((;i<${#x};++i))do z=${x:i:1};((t[${#t}?-1:0]<0))&&[[ $z != [][] ]]&&z=;case $z in +|-)((s[j]$z$z,s[j]&=255));;.)printf \\x$(printf %x ${s[j]});;\])((s[j]))&&i=${t[-1]}-1;unset t[-1];;\[)t+=($((s[j]&&t[${#t}?-1:0]>=0?i:-1)));;\>)((++j));;\<)((--j))esac done

