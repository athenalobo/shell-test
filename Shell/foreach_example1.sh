#!/bin/csh
#
#  FOREACH_EXAMPLE1.CSH
#  Using the FOREACH command with an explicit list.
#
#  This loop sets I to each value in the list.
#
foreach i ( 10 15 20 40 )
  echo $i
end
#
#  The values don't have to be numeric.
#
foreach i ( a b c 17 )
  echo $i
end
