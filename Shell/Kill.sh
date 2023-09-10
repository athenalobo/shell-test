#!/bin/sh
#	Kill pattern
#	Kill -SIG pattern...
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# This script runs ps and kills the processes that match the pattern.
#
# Different options are needed on different systems:
#	OPT=uwax	# Linux and POSIX
    OPT=gawux	# BSD
#   OPT=-elf	# Sys/V 
#
# Some commands we use:
	GREP=/usr/bin/egrep
	SED=/usr/bin/sed
	CUT=/usr/bin/cut
# You may also need to change the field used by the cut command:
	FLD=3
#
# Warning: It is very easy to kill more than you intended to kill.  Note that 
# on  some Unix systems, the "kill" command doesn't accept symbolic names for 
# signals; if yours is like this, then change the default '-TERM'  to  '-15'. 
# The  -<sig>  arg  may  only  be omitted when there's just a single pattern, 
# because if there are two or more args, the first is assumed to be a signal. 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

if [ $# -lt 1 ];then echo Usage: $0 -signal pattern;exit 1;fi
if [ $# -lt 2 ];then S='-TERM'; else S="$1";shift;fi
for p
do	PP=`ps $OPT \
		| $GREP "$p" \
		| $SED -e "s/^/ /" -e "/ $$ /d" -e "/ egrep /d" -e 's/  */#/g' \
		| $CUT -d# -f$FLD`
	echo "PP:"
	echo "$PP"
	echo ""
	echo kill $S $PP
	if [ -n "$PP" ];then
		exec kill $S $PP
	fi
done
exit 0