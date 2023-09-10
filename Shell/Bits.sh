#  Calculate the number of bits required to represent a numeric value as
#  an integer.

#  Copyright (c) 1989-1995 by Hamilton Laboratories.  All rights reserved.

proc bits( n )
   return ceil(log2 (n + 1))
end

bits $argv
