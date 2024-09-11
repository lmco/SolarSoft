#!/bin/csh -f 
#
#
################################# sswup ###################################
# Upgrade one or more SSW branches of SSW from UNIX command line
# branches updated are via pattern matching of parameters
#
# PreRequisities:
# SSW and Perl installed 
#    $SSW/site/setup/ssw_upgrade.mirror -or-
#    $SSW/site/mirror/ssw_upgrade.mirror exists
# (ie, at least one previous execution of ssw_upgrade.pro)
# See http://www.lmsal.com/solarsoft/ssw_upgrade.html  for details
#
# The UNIX aliases 'sswup' and 'sswupgrade' (synonyms) are defined
#    during execution of ssw setup
#
# Calling Sequence:
#   % sswupgrade pattern1 [pattern2 pattern3 ... patternN]    
#
# Calling Examples:
#
#   % sswupgrade                    # no parameters, just SSW/gen
#   % sswupgrade sxt                # just SSW/yohkoh/sxt/...
#   % sswupgrade yohkoh             # all SSW/yohkoh/xxx
#   % sswupgrade trace chianti eit  # trace, chianti packages and eit
#
#
# 14-March-2000 S.L.Freeland 
# 28-March-2000 S.L.Freeland - make the loop work...
###########################################################################

if ($#argv == 0) then
   set args="solarsoft_gen"
else
   set args=($argv)
endif

if (-e $SSW/site/mirror/ssw_upgrade.mirror) then 
   set mfile=$SSW/site/mirror/ssw_upgrade.mirror
else
   if (-e $SSW/site/setup/ssw_upgrade.mirror) then 
      set mfile=$SSW/site/setup/ssw_upgrade.mirror
   else
      echo "No ssw mirror file; need to run 'ssw_upgrade.pro' at least once"
      exit
   endif
endif


foreach branch ($args)
   set chk=`grep $branch $mfile | grep package=`
   foreach instr ($chk)
      if ($instr != "") then
         set package=`echo $instr | cut -f2 -d"="`
         echo "Mirroring package>> "$package
         $SSW/gen/mirror/mirror -p$package $mfile
      else
         echo "no package match for: "$instr
      endif
   end
end
exit
