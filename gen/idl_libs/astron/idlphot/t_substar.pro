pro t_substar,image,fitsfile,id,psfname, VERBOSE = verbose, NOPSF = nopsf
;+
; NAME:
;       T_SUBSTAR
; PURPOSE:
;       Driver procedure (for SUBSTAR) to subtract scaled PSF values 
; EXPLANATION:
;       Computes residuals of the PSF fitting program
;
; CALLING SEQUENCE:
;       T_SUBSTAR, image, fitsfile, id,[ psfname, /VERBOSE, /NOPSF ]
;
; INPUT-OUTPUT:
;       IMAGE -  On input, IMAGE is the original image array.  A scaled
;               PSF will be subtracted from IMAGE at specified star positions.
;               Make a copy of IMAGE before calling SUBSTAR, if you want to
;               keep a copy of the unsubtracted image array
; INPUTS:
;       FITSFILE  - scalar string giving the name of the disk FITS ASCII 
;               produced as an output from T_NSTAR.   
;
; OPTIONAL INPUTS:
;       ID -  Index vector indicating which stars are to be subtracted.  If
;               omitted, (or set equal to -1), then stars will be subtracted 
;               at all positions specified by the X and Y vectors.
;               (IDL convention - zero-based subscripts)
;       PSFNAME - Name of the FITS file containing the PSF residuals, as
;               generated by GETPSF.  SUBSTAR will prompt for this parameter
;               if not supplied.      
; OPTIONAL INPUT KEYWORD:
;       /VERBOSE - If this keyword is set and non-zero, then the value of each
;               star number will be displayed as it is processed.
;       /NOPSF - if this keyword is set and non-zero, then all stars will be 
;               be subtracted *except* those used to determine the PSF.
;               An improved PSF can then be derived from the subtracted image.
;               If NOPSF is supplied, then the ID parameter is ignored
; NOTES:
;       T_SUBSTAR does not modify the input FITS table.
;
; PROCEDURES USED:
;       FTGET(), FTINFO, READFITS(), REMOVE, SUBSTAR
; REVISION HISTORY:
;       Written, R. Hill, ST Sys. Corp., 22 August 1991
;       Added NOPSF keyword   W. Landsman        March, 1996
;       Use FITS format for PSF resduals         July, 1997
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Call FTINFO first to improve efficiency   W. Landsman  May 2000
;-
 On_Error,2

 if N_params() LT 2 then begin
    print,'Syntax -  T_SUBSTAR, im, fitsfile,[id, psfname, /VERBOSE, /NOPSF ]'
    print,'      im - Image Array'
    print,'      fitsfile - name of disk FITS ASCII table (from T_NSTAR)'
    print,"      id - vector of Star ID's to subtract (optional)"
    print,'      psfname - Name of FITS file containing the PSF'
    return
 endif 

 tab = readfits(fitsfile, htab,/exten)
 ftinfo, htab, ft_str
 x = ftget(ft_str,tab,'X_PSF') - 1.0
 y = ftget(ft_str,tab,'Y_PSF') - 1.0
 mag = ftget(ft_str,tab,'PSF_MAG')
 IF (N_elements(id) EQ 0) THEN id = -1
 if keyword_set(NOPSF) then begin 
        g = where(ft_str.ttype EQ 'PSF_CODE', Ng)
        if Ng EQ 0 then message,'ERROR -- FITS table missing PSF_CODE column'
        idpsf = ftget(ft_str,tab,'PSF_CODE')
        ipsf = where(idpsf)
        id = indgen(N_elements(x) )
        remove, ipsf, id
 endif
 if not keyword_set( VERBOSE )  then verbose = 0
 substar,image,x,y,mag,id,psfname, VERBOSE = verbose  ;Subtract scaled PSF stars

 RETURN
 END
