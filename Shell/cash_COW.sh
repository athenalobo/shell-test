#!/bin/csh
#
#  Modified:
#
#    16 November 2005
#
#  Author:
#
#    John Burkardt
#
echo "cash_COW.csh"
echo "  Set a shell variable 'cash',"
echo "  and an environment variable 'COW'."
echo " "
echo "  Before running this script, you should"
echo "  set these variables yourself, "
echo "    set cash = 10"
echo "    setenv COW 100"
echo "  and then, after running the script,"
echo "  check the current values of the variables again."
#
echo " "
if ( $?cash ) then
  echo "  Before: cash = $cash."
else
  echo "  Before: cash = NOT DEFINED."
endif
set cash = 30
echo "  After:  cash = $cash."
#
echo " "
if ( $?COW ) then
  echo "  Before: COW = $COW."
else
  echo "  Before: COW = NOT DEFINED."
endif
setenv COW 50
echo "  After:  COW = $COW."
echo " "
echo "  Now you should check the value of these variables"
echo "  by typing"
echo "    DOLLAR(cash)"
echo "  and"
echo "    DOLLAR(COW)."
