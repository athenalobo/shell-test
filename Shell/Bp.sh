#!/bin/sh
#	Bp file...
# Make backup copies of a list of files, by copying each to a file named
# the same, plus a final '-'.  We check for this file first, of course,
# and back it up if it exists.  See also Rm.
#
for	f
do	if	[ -f $f'-' ]
	then	Rm $f'-'
	fi
	cp $f $f-
done
