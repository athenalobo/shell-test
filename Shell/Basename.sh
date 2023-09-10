#  Emulate the POSIX basename command to extract just the last component
#  of a pathname, deleting any suffix, if specified.

#  Usage:   basename string [ suffix ]

#  Copyright (c) 1996 by Hamilton Laboratories.  All rights reserved.

proc basename( string, suffix )
   local base, i, j

   @ base = $string:t
   if (base == "") @ base = "\"

   if (suffix == "" && suffix != base) return base

   @ i = strlen(base)
   @ j = strlen(suffix)
   return i > j && lower(substr(base, i - j + 1)) == lower(suffix) ? ^
      substr(base, 1, i - j) : base
end

basename $argv
