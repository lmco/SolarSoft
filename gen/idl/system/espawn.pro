;+
; Project     : SOHO - CDS
;
; Name        : ESPAWN
;
; Purpose     : spawn a shell command and return STDIO and STDERR
;
; Category    : System
;
; Explanation : regular IDL spawn command doesn't return an error message
;
; Syntax      : IDL> espawn,cmd,out
;
; Inputs      : CMD = command(s) to spawn
;
; Keywords    : See SPAWN command
;
; Outputs     : OUT = output of CMD
;               ERR_RESULT = error string
;
; History     : Version 1,  24-Jan-1996, Zarro (ARC/GSFC) - written
;               Modified, 12-Nov-1999, Zarro (SM&A/GSFC) - made 
;                Windows compliant
;               Modified, 12-March-2000, Zarro (SM&A/GSFC) - sped
;                up with /NOSHELL (Unix only)
;               Modified, 22-May-2000, Zarro (EIT/GSFC) - added
;                /UNIQUE
;               Modified, 26-Mar-2002, Zarro (EER/GSFC) 
;                - sped up with caching 
;               29-Dec-2014, Zarro (ADNET) 
;                - cleaned up; removed caching
;               10-June-2019, Zarro (ADNET)
;                - initialized OUT
;               28-Apr-2022, Zarro (ADNET)
;                - added ERR_RESULT output argument
;               
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

pro espawn,cmd,out,err_result,_ref_extra=extra,err=err

print_out=~arg_present(out)
windows=os_family(/lower) eq 'windows'
if windows then spawn_cmd='win_spawn' else spawn_cmd='unix_spawn'

if print_out then begin
 call_procedure,spawn_cmd,cmd,_extra=extra,err=err
endif else begin 
 call_procedure,spawn_cmd,cmd,out,_extra=extra,err=err
endelse

err_result=err

return

end
