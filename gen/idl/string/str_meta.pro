;+
; Project     : VSO
;
; Name        : STR_META
;
; Purpose     : Return regular expression meta characters (*, . )
;
; Category    : utility string
;
; Syntax      : IDL> out=str_meta()
;
; Inputs      : None
;
; Outputs     : String array of IDL STREGEX meta characters
;
; Keywords    : None
;
; History     : 1-June-2022, Zarro (ADNET/GSFC) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function str_meta

mchars=['\','*','.','[',']','$','^','|','?','+','(',')','{','}']
return,mchars
end