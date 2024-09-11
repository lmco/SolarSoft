;+
; Project     : SOHO - CDS
;
; Name        : GET_GEV
;
; Purpose     : Wrapper around RD_GEV
;
; Category    : planning
;
; Explanation : Get GOES Event listing
;
; Syntax      : IDL>gev=get_gev(tstart)
;
; Inputs      : TSTART = start time 
;
; Opt. Inputs : TEND = end time
;
; Outputs     : GEV = event listing in structure format
;
; Keywords    : COUNT = # or entries found
;               ERR = error messages
;               QUIET = turn off messages
;               LIMIT = limiting # of days for time range
;               REMOTE = search remote instead of local Yohkoh archive
;               TIMES = string times of returned events
;
; History     : 20-June-1999,  D.M. Zarro.  Written
;               23-Jan-2012, Kim Tolbert.  Added ngdc keyword to read
;               older files (<25-aug-1991)
;               20-Dec-2016, Zarro. Added compile to sock_goes
;               5-Apr-2022, Zarro (ADNET) - added /REMOTE
;               7-Nov-2022, Zarro (ADNET) - added TIMES
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function get_gev,tstart,tend,count=count,err=err,quiet=quiet,nearest=nearest,$
                  limit=limit,remote=remote,_ref_extra=extra,times=times

err=''
count=0
rflag=0b
loud=~keyword_set(quiet)
gev=''
nearest=keyword_set(nearest)
times=''

;-- start with error checks

if ~have_proc('rd_gev') then begin
 sxt_dir='$SSW/yohkoh/gen/idl'
 if is_dir(sxt_dir,out=sdir) then add_path,sdir,/append,/expand
 if ~have_proc('rd_gev') then begin
  err='Cannot find RD_GEV in IDL !path. Need to install Yohkoh branch in SSW.'
  mprint,err,/cont
  return,''
 endif
endif

local_dir=chklog('DIR_GEN_GEV')

error=0
catch,error
if (error ne 0) then begin
 err=err_state()
 mprint,err 
 catch, /cancel
 message,/reset
 gev=''
 goto,bail
endif

err=''
t1=anytim2utc(tstart,err=err)
if err ne '' then get_utc,t1
t1.time=0

err=''
t2=anytim2utc(tend,err=err)
if err ne '' then begin
 t2=t1
 t2.mjd=t2.mjd+1
endif

;-- shift to end of 24 hr period

;t2.time=0
;t2.mjd=t2.mjd+1

if t2.mjd le t1.mjd then begin
 err='End time must be greater than Start time.'
 if loud then mprint,err
 return,''
endif

if is_number(limit) then begin
 if (abs(t2.mjd-t1.mjd) gt limit) then begin
  err='Time range exceeds current limit of '+num2str(limit)+' days'
  if loud then mprint,err
  return,''
 endif
endif

if keyword_set(remote) then begin
 mklog,'DIR_GEN_GEV',''
 mprint,'Searching remotely...'
 rflag=1b
endif else begin
 if is_blank(local_dir) then begin
  err='Warning DIR_GEN_GEV not defined. Searching remotely...'
  mprint,err
  rflag=1b
 endif
endelse

if rflag then recompile,'sock_goes',/quiet

;-- call RD_GEV

err=''
if loud then mprint,'Retrieving GEV data for '+ anytim2utc(t1,/vms),/cont
rd_gev,anytim2utc(t1,/vms),anytim2utc(t2,/vms),gev,_extra=extra,nearest=nearest

if is_struct(gev) then begin
 gtimes=anytim(gev) & times=anytim(gev,/yoh)
 count=n_elements(gev)  
 if ~nearest then begin  
  ok=where(gtimes ge anytim(t1) and gtimes le anytim(t2),count)
  if count gt 0 then begin
   gev=gev[ok] & times=times[ok]
  endif
 endif 
endif
 
if count eq 0 then begin
 err='No GOES event data found for specified times. Try using /nearest.'
 mprint,err
 count=0
 gev=''
endif

bail:

if rflag then begin
 mklog,'DIR_GEN_GEV',local_dir
 recompile,'rd_week_file',/quiet
 recompile,'weekid',/quiet
endif

return,gev

end


