;+
; Project     : VSO
;
; Name        : STR_ESCAPE
;
; Purpose     : Escape regular expression meta characters (*, . )
;
; Category    : utility string
;
; Syntax      : IDL> out=str_escape(in)
;
; Inputs      : IN = input string to escape (e.g. 'test.gif')
;
; Outputs     : OUT = output escaped string (e.g. 'test\.gif')
;
; Keywords    : EXCLUDE = characters to not escape
;               ONLY = characters to only escape 
;
; History     : 16-June-2016, Zarro (ADNET/GSFC)
;               24-February-2022, Zarro (ADNET/GSFC) - improved
;               26-May-2022, Zarro (ADNET/GSFC) - add EXCLUDE/ONLY
;
; Contact     : dzarro@solar.stanford.edu
;-

function str_escape,input,exclude=exclude,only=only

if ~is_string(input,/scalar) then return,''

mchars=str_meta()

if is_string(only) then begin
 chars=strtrim(only,2) 
 chk=where(chars ne '',count)
 if count gt 0 then chars=chars[chk]
endif else chars=str_remove(mchars,exclude,count=count)
if count eq 0 then return,input

slen=strlen(input)
for i=0,slen-1 do begin
 char=strmid(input,i,1)
 chk=where(char eq chars,dcount)
 if dcount gt 0 then begin
  if i eq 0 then bchar='' else bchar=strmid(input,i-1,1)
  if char eq '\' then begin
   if i eq (slen-1) then a1char='' else a1char=strmid(input,i+1,1)
   if i eq (slen-2) then a2char='' else a2char=strmid(input,i+2,1)
   chk1=where(a1char eq mchars,count1)
   chk2=where(a2char eq mchars,count2)
   if ((count1 eq 0) && (bchar ne '\')) || $
      ((count2 gt 0) && (a1char eq '\')) then char='\'+char
  endif else begin 
   if bchar ne '\' then char='\'+char
  endelse
 endif
 if i eq 0 then output=char else output=output+char
endfor

return,output
end 
