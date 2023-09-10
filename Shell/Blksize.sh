#include <windows.h>
#include <stdlib.h>

void main( int argc, char **argv )
   {
   HANDLE Stdin = GetStdHandle(STD_INPUT_HANDLE),
      Stdout = GetStdHandle(STD_OUTPUT_HANDLE);
   char *buffer, *p;
   DWORD length, blocksize, remaining;
   SYSTEM_INFO sysinfo;

   GetSystemInfo(&sysinfo);
   buffer = (char *)(((ULONG)malloc(blocksize + sysinfo.dwPageSize) +
         sysinfo.dwPageSize) & ~(sysinfo.dwPageSize - 1));

   while (ReadFile(Stdin, buffer, blocksize, &length, NULL) && length)
      {
      if (remaining = blocksize - length)
         {
         p = buffer + length;
         while (remaining &&
               ReadFile(Stdin, p, remaining, &length, NULL) && length)
            {
            remaining -= length;
            p += length;
            }
         length = blocksize - remaining;
         }
      WriteFile(Stdout, buffer, length, &length, NULL);
      }

   CloseHandle(Stdin);
   CloseHandle(Stdout);
   ExitProcess(0);
   }
