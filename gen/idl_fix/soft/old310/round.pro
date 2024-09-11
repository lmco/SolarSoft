function round,X
;+
; ROUTINE:
;  ROUND
; PURPOSE:
;   Return integer closest to its argument
; CALLING SEQUENCE:
;   Result = ROUND(X)
;
;   This is fixup for IDL versions prior to V3.1
;
; WRITTEN:
;   11-jul-94, J. R. Lemen
;-
on_error,1
if n_elements(X) eq 0 then message,'Variable is undefined:  '

Result = lonarr(n_elements(X))

ii = where(X gt 0,nc)
if nc gt 0 then Result(ii) = long(X(ii) + .5)

ii = where(X lt 0,nc)
if nc gt 0 then Result(ii) = long(X(ii) - 0.5)

return,Result
end
