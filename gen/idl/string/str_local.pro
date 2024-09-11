;+
; Project     : VSO
;
; Name        : STR_LOCAL
;
; Purpose     : Convert path delimiters in path/filename to local name taking into account STREGEX metacharacters
;
; Category    : utility string
;
; Syntax      : IDL> output=str_local(input)
;
; Inputs      : INPUT = string to escape to convert (e.g. \test\.dat)
;
; Outputs     : OUTPUT = converted escaped string (e.g. \\test\.data)
;
; Keywords    : UNIX = set to convert to UNIX delimiter otherwise use local OS.
;
; History     : 1-June-2022, Zarro (ADNET/GSFC) - written
;
; Contact     : dzarro@solar.stanford.edu
;-

function str_local,input,unix=unix

if ~is_string(input,/scalar) then return,''

delim=get_delim() 
if keyword_set(unix) then delim='/'

slen=strlen(input)
mchars=str_meta()

output=''
for i=0,slen-1 do begin
 item1=strmid(input,i,1)

 if (item1 eq '\') then begin
  if ((i+1) lt slen) then begin
   item2=strmid(input,i+1,1)  
   chk=where((item2 eq mchars),count)
   if count gt 0 then begin
    output=output+item1+item2
    i=i+1
    continue
   endif
  endif 
 endif

 if (item1 eq '\') || (item1 eq '/') then begin
  if delim eq '\' then new='\'+delim else new=delim
  output=output+new
  continue
 endif
   
 output=output+item1

endfor    

return,output
end
