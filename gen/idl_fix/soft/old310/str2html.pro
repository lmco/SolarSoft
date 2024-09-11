function str2html, text, _extra=_extra, headers=headers, $
   min_col=min_col, min_line=min_line
;
;+
;   Name: str2html
;
;   Purpose: format a block of free-form ascii text into a standard 'html'
;
;   Method:
;      identify tables - block with <p><pre>TABLE</pre> ;
;      replace null lines with <p>			; paragraph
;      
;   History:
;      29-mar-1995 (SLF)
;      30-mar-1995 (SLF) - for pre-keyword inheritance IDL (dummy)
;-

remtab,text,ttext				; tabs -> spaces

; bracket tables with <p><pre>TABLE</pre>
tables=where_table(ttext,tcnt,min_col=min_col, min_line=min_line) ; find tables

if tcnt gt 0 then begin
   ttext(tables(*,0))='<p><pre>' + ttext(tables(*,0))
   ttext(tables(*,1))=ttext(tables(*,1)) + '</pre>'
endif

nulls=where(ttext eq '',ncnt)
nnulls=where(ttext ne '',nncnt)		; not nulls

if ncnt gt 0 then ttext(nulls)='<p>'

if keyword_set(headers) then begin
   hlev=strtrim(headers < 5,2)
   headers=where(deriv_arr(nulls) eq 2,hcnt)
   hss=nulls(headers)+1 < (n_elements(ttext)-1) 
   if hcnt gt 0 then ttext(hss) = $
      '<h'+hlev+'>' + ttext(hss) + '</h' + hlev + '>'
endif


return,ttext
end
