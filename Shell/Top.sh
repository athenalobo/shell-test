#!/bin/sh
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
# This is a wrapper around the "top" command that figures out how many #
# lines can be written to the current window, and tells top to display #
# all processes that will fit.                                         #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -#
x=`/usr/5bin/stty -a | head -1`
r=`expr "$x" : '.* \([0-9]*\) rows.*' - 6`
#echo Room for $r processes.
exec top -SI $r
