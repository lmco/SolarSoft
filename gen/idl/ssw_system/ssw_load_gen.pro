;+
; Project     : HESSI
;                  
; Name        : SSW_LOAD_GEN
;               
; Purpose     : Preload $SSW/gen/idl in !path
;                             
; Category    : utility
;               
; Syntax      : IDL> ssw_load_gen
;
; Inputs      : None
; 
; Outputs     : None
;
; Keywords    : SITE = include SITE directories
;                                   
; History     : 28-Nov-2022, Zarro (ADNET) - written
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro ssw_load_gen,_ref_extra=extra,site=site,err=err

err=''
ssw=getenv('SSW')
if ssw eq '' then begin
 err='SSW environment variable undefined.'
 message,err,/cont  
 return
endif

if strlowcase(!version.os_family) eq 'windows' then begin
 dlim='\' & plim=';'
endif else begin
 dlim='/' & plim=':'
endelse

error=0
catch,error
if (error ne 0) then begin
 err=!error_state.msg
 message,err,/cont
 catch, /cancel
 message,/reset  
 return
endif

;-- ensure GEN is loaded in path

gen_idl='\'+dlim+'gen\'+dlim+'idl\'+dlim
chk=stregex(!path,gen_idl,/bool,/fold)
if ~chk then begin
 message,'Adding GEN to path',/info 
 gen_path=expand_path('+'+SSW+dlim+'gen'+dlim+'idl')
 lib_path=expand_path('+'+SSW+dlim+'gen'+dlim+'idl_libs')
 gpath=gen_path+plim+lib_path
 if !path eq '' then !path=gpath else !path=gpath+plim+!path
endif

;-- add SITE

site=keyword_set(site)
if site then begin
 SSW_SITE=ssw+dlim+'site'+dlim+'idl'
 chk=strpos(!path,SSW_SITE) gt -1
 if ~chk then begin
  if file_test(SSW_SITE,/direc) then begin
   spath = expand_path('+'+SSW_SITE)
   message,'Adding SITE to path',/info 
   if !path eq '' then !path=spath else !path=spath+plim+!path
  endif
 endif
endif

message,/reset

return & end
