FUNCTION GAMINC,P,X
;+
; NAME:
;   GAMINC
; PURPOSE:
;   Compute the function = exp(X) / X^P * Int[exp(-X)*X^(P-1)dx]
;                                       (Int = Integrate from X to Infinity)
; CALLING SEQUENCE:
;   Result = gaminc(P,X)		; X>0
;
; INPUTS:
;   X and P	See expression above for details
;		X and P must be a scalars
; RETURNS:
;	Expression returned is a vector the same length as X.
; HISTORY:
;    1-sep-93, J.R. Lemen (LPARL), Converted from a very old SMM Fortran program
;		            Not optimized for IDL, but eliminated "go to" stmts.
;-
on_error,2			; Return to caller

; Check the size of P -- must be a scalar

if (n_elements(P) ne 1) or (n_elements(X) ne 1) then begin
  tbeep
  message,' Error: P and X must be a scalars',/cont
  help,P,X
  return,-1
end 

BIG=1.E10
CUT=1.E-8
Y=1.0-P
Z=X+Y+1.0
CNT=0.0
VV = [1.,X,X+1.,Z*X,0.,0.]
GAMINC=VV(2)/VV(3)

while 1 do begin			; Infinite loop
  repeat begin

	CNT=CNT+1.0
	Y=Y+1.0
	Z=Z+2.0
	YCNT=Y*CNT
	VV(4)=VV(2)*Z-VV(0)*YCNT
	VV(5)=VV(3)*Z-VV(1)*YCNT

	IF VV(5) ne 0.0 then begin
	  RATIO=VV(4)/VV(5)
	  REDUC=ABS(GAMINC-RATIO)
	  IF REDUC le CUT then begin			; GO TO 30
	    IF REDUC LE RATIO*CUT then return,Gaminc	; Only way to return
	  endif
	  GAMINC=RATIO
	endif 
	for i=0,3 do VV(i) = VV(i+2)
  endrep until ABS(VV(4)) ge BIG

; SCALE TERMS DOWN TO PREVENT OVERFLOW
  for i=0,3 do VV(I)=VV(I)/BIG
endwhile

end

