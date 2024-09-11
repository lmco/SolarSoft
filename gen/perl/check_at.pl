# check_at.pl
#
# perl routine to find any ssw update jobs that are already scheduled
# (by looking for the string "ssw\site\setup\daily.cmd" in the at commands)
# and delete them.  This should be run in the ssw setup.bat installation
# script before scheduling the new update by adding the line:
#       c:\perl\bin\perl.exe c:\ssw\site\setup\check_at.pl
# (substitute the correct path in both cases).
# To test, try calling it with the "test" parameter: 
#       c:\perl\bin\perl.exe c:\ssw\site\setup\check_at.pl "test"
# and it will list the at jobs it would have deleted.
#
# Kim 3/7/00

{
local ($test, @lines, $line, @words );

$test = 0;
if ($ARGV[0] eq 'test') { $test=1 ;}

system 'at | find "ssw\site\setup\daily.bat" > temp.txt';

open (FILE, "temp.txt");
@lines = <FILE>;

foreach $line ( @lines ) {
        @words = split (/[ \t\n]+/, $line);
        if ($test) 
                {system "at $words[1]";}
        else
                {system "at $words[1] /delete";}
        }

close FILE;
system "del temp.txt";

$exit_status=1;
}



