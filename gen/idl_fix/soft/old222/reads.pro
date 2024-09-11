pro reads,inbuffer,p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15, $
		format=format
;
;+
;   Name: reads
;
;   Purpose: emulate IDL supplied <reads> for old idl versions
;
;   Input Paramters:
;      inbuffer string/string array to read from 
;
;   Output Parameters:
;      outarray output string/string array
;   
;   Keyword Paramters:
;      format - if present, std idl format used when reading inbuffer into 
;		outarray 
;
;
;   Restrictions:
;      uses execute statement, so no recursive calls allowed 
;
;   History:
;      14-apr-1993 SLF (expanded on R.Schwartz version)
;      Upgraded to use system independent file names and deletion method
;      and allow up to 16 output parameters
;-
; write inbuffer to temporary file
scratchf,lun,name=name			;open a scratch file with ind name
printf,lun,inbuffer,format='(a)'	;handle string arrays properly
free_lun,lun				;finished write so close it
;
; generate parameter list based on number of outputs desired
plist=strcompress('p' + sindgen(n_params()-1),/remove) ; less 1 for inbuffer
plist=arr2str(plist)
;
; open the file (again) and read it back into desired output paramters
openu,lun,/get_lun,name,/delete			;delete file on close
; build execute string
fmt=['',',format=format']
exestr='readf,lun,' + plist + fmt(keyword_set(format))
exestat=execute(exestr)

if not exestat then message,/info,'Problem with reads execution...'
;
; close (and delete) the file
free_lun,lun

return
end

