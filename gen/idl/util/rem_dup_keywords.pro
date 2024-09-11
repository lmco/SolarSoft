;+
; Project     : VSO
;
; Name        : REM_DUP_KEYWORDS
;
; Purpose     : remove duplicate keywords from EXTRA
;
; Category    : utility 
;
; Syntax      : IDL> output=rem_dup_keywords(extra)
;
; Inputs      : EXTRA = keyword extra in structure or string format
;
; Outputs     : NEXTRA = duplicate keywords removed - one with largest
;                       string length is favored.
;
; Keywords    : VERBOSE = print removed keywords
;
; History     : 25-Feb-2013, Zarro (ADNET) - written.
;               24-Mar-2022, Zarro (ADNET) - fixed bug when removing more than one duplicate keyword.
;-

function rem_dup_keywords,extra,verbose=verbose

verbose=keyword_set(verbose)
if ~is_string(extra) && ~is_struct(extra) then return,null()

if is_struct(extra) then textra=tag_names(extra) else textra=extra
np=n_elements(textra)
if np eq 1 then return,extra

;-- cycle thru each keyword. If it matches the start of another
;   keyword in the list, then keep the longest one.

textra=strupcase(textra)
for i=0,np-1 do begin
 if is_blank(textra[i]) then continue
 chk1=where(stregex(textra,'^'+textra[i],/bool,/fold),count)
 if (count gt 1) then begin
  matches=textra[chk1]
  lens=strlen(matches)
  chk2=where(lens eq min(lens),scount)
  if scount gt 0 then begin
   rtag=textra[chk1[chk2]]
   if verbose then mprint,'Removing '+rtag
   textra[chk1[chk2]]=''
   rtags=append_arr(rtags,rtag)
  endif
 endif
endfor

ok=where(textra ne '',count)
if count gt 0 then textra=textra[ok]
if count eq 1 then textra=textra[0]
if count eq 0 then textra=''

;-- return structure if it was input

if is_struct(extra) then textra=rem_tag(extra,rtags)

return,textra

end
