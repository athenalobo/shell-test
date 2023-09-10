#!/bin/sh
#
#SYNOPSIS
#	Cp [opt] file... target
#	Lc [opt] file... target
#	Ln [opt] file... target
#	Mv [opt] file... target
#
#DESCRIPTION
# This is like the Unix command with the  lower-case  names,  but  it
# does a recursive rename (via Rm) on the targets first. Note that it
# doesn't complain if the target already exists. It also works if the
# target  is  a  directory, including the case where the file already
# exists.
#
# This has been rewritten in C, but it's often useful  to  have  this
# script  version around for bootstrapping purposes.  There are still
# some potential problems, such as the lack of the basename and  test
# commands in some libraries. We use /bin/test because of problems in
# the shell's builtin [...] syntax on some systems.
#
#AUTHOR
# John Chambers <jc@trillian.mit.edu> 1987, 1989, 1993, 1997.

#set -x
#echo 'Call:' $0 $*
Cmd=`basename $0`
case "$Cmd" in
	Ln)	cmd=ln;;
	Cp)	cmd=cp;;
	LnCp)	cmd=ln; cmd2=cp;;
	Lc)	cmd=ln; cmd2=cp;;
	Mv)	cmd=mv;;
	*)	echo 'Unknown command "'$Cmd'"'; exit 1;;
esac
opt=''
case $1 in
	-*) opt=$1;shift;;
esac
if [ $# -lt 2 ];then echo Usage: $0 old new; exit 1;fi
for t do : ; done
while	[ $# -gt 1 ]
do	if test -d $t
	then	b=`basename $1`
		if [ -f $t/$b ];then Rm $t/$b;fi
		$cmd $opt $1 $t/$b 2>/dev/null || {
			if [ -n "$cmd2" ];then $cmd2 $opt $1 $t/$b;fi
		}
	else	if [ -f $t ];then Rm $t;fi
		$cmd $opt $1 $t 2>/dev/null || {
			if [ -n "$cmd2" ];then $cmd2 $opt $1 $t;fi
		}
	fi
	shift
done
exit 0
