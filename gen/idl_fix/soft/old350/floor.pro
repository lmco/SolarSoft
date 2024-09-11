
function floor,X

;+
; ROUTINE:
;  FLOOR
; PURPOSE:
;   Return the closest integer less than or equal to its argument.
; CALLING SEQUENCE:
;   Result = FLOOR(X)
;
;   This is fixup for IDL versions prior to V3.1
;
; WRITTEN:
;   29-Nov-95, R. Kano
;-

on_error,1
if n_elements(X) eq 0 then message,' Variable is undefined:  '

return, long(X) - (X lt 0)*(X ne long(X))
end

