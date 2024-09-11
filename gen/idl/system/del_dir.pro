;+
; Project     : HESSI
;                  
; Name        : DEL_DIR
;               
; Purpose     : wrapper around FILE_DELETE that checks protections
;                             
; Category    : system utility
;               
; Syntax      : IDL> del_dir,dir
;
; Inputs      : DIR = directory string names
;                                        
; Outputs     : None
;
; Keywords    : RECURSE = set to recurse on directories
;               CHMOD = set to force write access to directories
;                   
; History     : 10-Jan-2019, Zarro (ADNET) - written
;               26-May-2022, Zarro (ADNET) - added CHMOD
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro del_dir,dir,_extra=extra,err=err,verbose=verbose,chmod=chmod

err=''
verbose=keyword_set(verbose)

chmod=keyword_set(chmod)
if chmod then begin
 chmod,dir,_extra=extra,/u_write,/u_read,err=err,verbose=verbose
 if is_string(err) then return
endif

for i=0,n_elements(dir)-1 do begin

 error=0
 catch,error
 if error ne 0 then begin
  err=err_state()
  mprint,err
  catch,/cancel
  continue
 endif

 tdir=strtrim(dir[i],2)
 if is_blank(tdir) then continue
 if ~file_test(tdir,/write,/direc) then continue
 file_delete,tdir,_extra=extra,/allow_nonexistent,verbose=verbose
endfor

return & end
