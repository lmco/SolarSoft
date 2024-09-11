function temporary,a   
; 
;+
;   Name: temporary
;
;   Purpose: mask routine to allow older versions of idl to run
;	     software referencing the 'new' IDL function, temporary
;
;   Output: function just returns the input parameter
;
;   Restrictions: this routine should be in a directory which only is
;   		  included in !path if the idl version is older than 2.2.1
;
;   Side Effects: if this routine is compliled on systems running idl
; 		   release newer than 2.2.1, the IDL temporary function
;		   is not accesible.
;-
return,a	; tough one
end
