pro rmosaic
;
;+
;   Name: rmosaic
;
;   Purpose: spawn mosaic job, 'solar' hotlist lookup
;
;   Calling Sequence:
;      rmosaic
;
;   History:
;      26-Jan-95 (SLF) 
;
;   Restrictions:
;      if no local version, environmental <mosaic_host> should
;      point to remote host - in this case, must have RSH priviledge
;-

hotlist=rd_tfile(concat_dir('$DIR_GEN_DATA','url.solar')) ; 
remtab,hotlist,notablist
notabcol=str2cols(notablist,'#')
ss=wmenu_sel(strjustify(notabcol(1,*)) + ' ' + strjustify(notabcol(0,*)),/one)

if ss(0) eq -1 then pattern='' else $
   pattern=strtrim(notabcol(1,ss(0)))

; spawn the rmosaic job
rmos='csh $DIR_GEN_SCRIPT/rmosaic' + ' ' + pattern  
message,/info,"Calling: " + rmos
spawn,rmos
return
end
