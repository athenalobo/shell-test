#!/bin/csh
#
#  This C shell script demonstrates how a shell script can process
#  its command line arguments.
#
#  The expression "$#argv" returns the number of elements in ARGV,
#  which is a built-in C shell variable that contains the command line arguments.
#
echo "Number of command line arguments is " $#argv
#
#  The first command line argument, if it exists, can be echoed as follows:
#
echo " "
echo "First command line argument is " $argv[1]
#
#  The SHIFT command, if used with no arguments, is applied to ARGV.
#  It overwrites the current value of ARGV[1] by that of ARGV[2], and so on.
#  The number of command line arguments is reduced by 1.
#
#  In this way, any number of command line arguments can be handled.
#
#  The WHILE loop eventually stops because the number of command line arguments
#  becomes 0.
#
echo " "
set i = 0;
while ( $#argv )
  @ i = $i + 1;
  echo "Command line argument " $i " is " $argv[1]
  shift
end