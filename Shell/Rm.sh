:
#	Rm file...
# Remove files by appending '-' to their names.  This is done recursively, of
# course, resulting in a series of files with lots of hyphens on their names.
# See also Bl, Bp, Cp, Ln, Mv.  This should be rewritten in C...
# This script is obsolete; the Rm.c program is much faster.
for f
do	if [ -f $f ]
	then	
		if [ -f $f'-' ]
		then	
			case `basename $f` in
			?????????????) rm -f $f'-';;	# Sys/V 14-byte limit.
			*)	$0 $f'-';;			# Back up the backup.
			esac
		fi
		mv $f $f'-'
	fi
done
exit 0

