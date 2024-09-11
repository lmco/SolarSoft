;+
; Project     : VSO
;
; Name        : SOCK_MIRROR
;
; Purpose     : Mirror files in directory (and its subdirectories) 
;
; Category    : utility system sockets 
;
; Syntax      : IDL> sock_mirror,local_dir,remote_dir
;
; Inputs      : LOCAL_DIR = local directory name to mirror to
;                         = or package file name with keywords
;                         (cf. PERL/Mirror)
;               REMOTE_DIR = remote directory name with URL to mirror from 
;
; Outputs     : None
;
; Keywords    : ERR = error string
;               RUN = set to actually execute mirror
;               LOG = summary log
;               QUIET = set to not print log 
;               DETAIL = set to output more details
;               FORCE = force mirror  
;               NO_CACHE = skip checking last cache for file sizes and
;               timestamps
;               LATEST = set to recheck for latest Mirror object
;
; History     : 13 May 2020, Zarro (ADNET)
;               23 May 2022, Zarro (ADNET) - added /LATEST
;
; Contact     : dzarro@solar.stanford.edu
;-

pro sock_mirror,source,target,err=err,_ref_extra=extra,quiet=quiet,latest=latest

common sock_mirror,latest_version,mobj
recheck=keyword_set(latest) || ~exist(latest_version)

verbose=~keyword_set(quiet)
err=''

if n_params() eq 0 then begin
 help=['',"Run as: sock_mirror,source,target",$
       "Example => sock_mirror,'https://sohowwww.nascom.nasa.gov/solarsoft/gen/idl','$SSW/gen/idl'",$
       '',"Or as: sock_mirror,package",$
       "Example => sock_mirror,'gen.txt'",'']
 print,transpose(help)
 return
endif

if exist(latest_version) then begin
 if ~latest_version && ~recheck then recheck=1b
endif

error=0
catch, error
if (error ne 0) then begin
 catch,/cancel
 err=err_state()
 mprint,err
 message,/reset
 return
endif

;-- ensure latest version of mirror object is used

if recheck then begin
 ltime=0L & stime=0L & mtime=0l
 lfile='' & sfile='' & mfile=''
 lchk=have_proc('mirror__define',outfile=lfile)
 if file_test2(lfile,/reg) then ltime=file_time(lfile,/tai)-ut_diff(/sec)

 sfile=ssw_server()+'/solarsoft/gen/idl/objects/mirror.sav'
 schk=sock_check(sfile,date=sdate)
 if schk then stime=anytim2tai(sdate)

 mfile=local_name('$SSW/gen/idl/objects/mirror.sav')
; mchk=file_test(mfile,/reg)
; if mchk then mtime=file_time(mfile,/tai)

 times=[ltime,stime,mtime]
 files=[lfile,sfile,mfile]
; dprint,files
; dprint,anytim2utc(times,/vms)

 tmax=max(times,tindex)
 if tmax eq 0 then begin
  err='Mirror object not found on this system.'
  mprint,err
  latest_version=0b
  return
 endif
 
 fmax=files[tindex[0]]
 if verbose then mprint,'Using '+fmax
 if is_url(fmax) then sock_get,fmax,out_dir=get_temp_dir(),local=ofile,/clobber,err=err else ofile=fmax
 oext=file_break(ofile,/ext)
 if oext eq '.sav' then restore,file=ofile else recompile,ofile
 latest_version=1b
endif

if ~obj_valid(mobj) then mobj=obj_new('mirror')
if n_params() eq 1 then begin
 mobj->mirror,source,_extra=extra,err=err,verbose=verbose,/recurse 
endif else begin
 mobj->mirror,source,target,_extra=extra,err=err,/recurse,verbose=verbose
endelse
 
return & end
