;+
; Project     : HESSI
;                  
; Name        : SSW_LOAD
;               
; Purpose     : Platform/OS independent SSW startup.
;               Executes IDL startups and loads environment variables for
;               instruments and packages in $SSW_INSTR
;                             
; Category    : utility
;               
; Syntax      : IDL> ssw_load
;
; Inputs      : None
; 
; Outputs     : None
;
; Keywords    : VERBOSE - set for verbose output
;               ERR - error string
;               ENV_ONLY = load environment only
;               SITE = include SITE directories
;                                   
; History     : 30-Apr-2017, Zarro (ADNET) - written
;               28-Nov-2022, Zarro (ADNET) - separated GEN and INSTR loading
;
; Contact     : dzarro@solar.stanford.edu
;-    

pro ssw_load,_ref_extra=extra

err=''
ssw_load_gen,err=err,_extra=extra
if err ne '' then return

ssw_load_instr,_extra=extra

return & end
