#!/bin/sh
#	Inc [mbox]
# This mimics the mh "inc" command, by running unpackmail on the user's
# mailbox, and unpacking it into $HOME/Mail, which we create if necessary.
#
# BUG: No file locking is done; incoming mail may be lost.
# BUG: We destroy the input file; if there was new mail, we destroy it, too.

if [ $# -lt 1 ];then set /var/mail/$LOGNAME;fi
if [ -s $1 ];then
	test -d $HOME/Mail/inbox || mkdir -p $HOME/Mail/inbox/
	unpackmail $HOME/Mail/inbox/ <$1
	if [ $? = 0 ];then
		>$1
	fi
fi
