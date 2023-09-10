#!/bin/csh
#
#  FOREACH_EXAMPLE2.CSH
#  Using the FOREACH command with a list created by a system command.
#
#  The command "ls -1" creates a list of files in the current directory.
#  The "-1" parameter ensures that each file name is on a separate line.
#
#  The FOREACH command sets the variable FILE to each filename in the list.
#
foreach file ( `ls -1` )
  echo " "
  echo $file
  wc $file
end
