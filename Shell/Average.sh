#  Find the average of any numeric values in a list.  If none of the
#  elements are numeric, return 0.

#  Copyright (c) 1996 by Hamilton Laboratories.  All rights reserved.

proc average( values )
   local i, j, n
   @ j = 0
   @ n = 0
   if ($#values) then
      for i = 0 to $#values - 1 do
         if (isnumber(values[i])) then
            @ j += values[i]
            @ n++
         end
      end
      if (n) @ j /= n
   end
   return j
end

average $argv
