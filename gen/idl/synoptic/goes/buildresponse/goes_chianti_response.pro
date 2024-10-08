
; in a test directory do
;  .run goes_chianti_response
;  resp=goes_chianti_response(/all, have_spec)  ; if you already have the .genx files
;      or 
;  resp=goes_chianti_response(/all)  ; if you don't already have the .genx files

;------------------------ generate_spectra.pro ------------------------
;+
; PROJECT:
;     GOES
;
; PURPOSE:
;     Generate CHIANTI spectra for calculation of GOES responses.
;
; CATEGORY:
;       GOES
;
; CALLING SEQUENCE:
;       generate_spectra [, /photospheric ]
;
; INPUTS:
;       Set /PHOTOSPHERIC for photospheric abundances, default is coronal
;
; OUTPUTS:
;       Individual SAVEGEN files containing spectra SPC for each of 62
;       temperatures, labelled ch<VERS>_cor_3e10_1e27_<LOGT>.genx or
;       ch<VERS>_pho_3e10_1e27_<LOGT>.genx
;
; PROCEDURE:
;     Calls MAKE_CHIANTI_SPEC
;
; MODIFICATION HISTORY:
;     SW 2005 Jan: original version, "worst piece of code in SolarSoft" per Richard
;     RS 2020: Richard made it readable
;-
;
; --------------------------------------------------------------------------
;

pro gcr_generate_spectra, path = path, photospheric=photospheric


  ; get chianti version
  chianti_version, vers
  default, path, '.'
  flpho = file_search(path, 'ch'+vers+'_pho_3e10_1e27_*genx', count = npho)
  flcor = file_search(path, 'ch'+vers+'_cor_3e10_1e27_*genx', count = ncor)
  fbase = strmid( ssw_strsplit(flcor,'1e27_',/tail), 0,4)

  ltemp = reform( float(  fbase ))
  temp = 10.^(ltemp-6.)
  ;No need to generate spectra if they are already there - but now controlled by HAVE_SPEC keyword to goes_chianti_response
  if keyword_set(photospheric) then begin
     if npho eq 101 and total( abs( fix( minmax( temp + 0.5)) - [1.,100.])) eq 0 then begin
        print,'WARNING: proceeding will replace photospheric-abundance spectrum files already present.'
        wait,3
     endif
  endif else begin
     if ncor eq 101 and total( abs( fix( minmax( temp + 0.5)) - [1.,100.])) eq 0 then begin
        print,'WARNING: proceeding will replace coronal-abundance spectrum files already present.'
        wait,3
     endif
  endelse

  ; inputs
  int_xrange=[0.01,20]          ; wavelength range, Angstrom
  ang=0.01 & inst=0.03          ; wavelength bin size, resolution
  density=3.e10
  iso_logem=27.0
  ; ioneq_name=!xuvtop+'/ioneq/mazzotta_etal_ext.ioneq'
  print,'Using the new chianti.ioneq'
  ioneq_name=!xuvtop+'/ioneq/chianti.ioneq'
  min_abund=4.00e-11
  xrange=int_xrange         ; wavelength range for spectrum
  chianti_version, vers

  for i=0,100 do begin       ; start temperature loop

    iso_logt=6.0+i*0.02

    ; cal to ch_synthetic to generate line list

    ch_synthetic, int_xrange(0), int_xrange(1), $
      output=tran, $
      err_msg=err_msg, msg=msg, $
      density=density, $
      all=1, $
      LOGT_ISOTHERMAL=iso_logt, $
      logem_isothermal=iso_logem, $
      ioneq_name=ioneq_name

    ; then call make_chianti_spec to add lines to continuum


    if not keyword_set(photospheric) then begin

      abund_name=!xuvtop+'/abundance/sun_coronal_1992_feldman_ext.abund'
      delvarx, lambda     ; clear lambda array, will be returned by routine
      make_chianti_spec,tran, lambda, spc, BIN_SIZE=ang,$
        INSTR_FWHM=inst, wrange=xrange, $
        ALL=1, continuum=1, $
        ABUND_NAME=ABUND_NAME, $
        MIN_ABUND=MIN_ABUND, $
        err_msg=err_msg, /VERBOSE
      save_file='ch'+vers+'_cor_3e10_1e27_'+string(iso_logt,format='(f4.2)')+'.genx'
      savegen, struct=spc, file=save_file

    endif else begin
      ; repeat for photospheric abundance: line list the same, change abundance file

      abund_name=!xuvtop+'/abundance/sun_photospheric_1998_grevesse.abund'
      delvarx, lambda     ; clear lambda array, will be returned by routine
      make_chianti_spec,tran, lambda, spc, BIN_SIZE=ang,$
        INSTR_FWHM=inst, wrange=xrange, $
        ALL=1, continuum=1, $
        ABUND_NAME=ABUND_NAME, $
        MIN_ABUND=MIN_ABUND, $
        err_msg=err_msg, /VERBOSE
      save_file='ch'+vers+'_pho_3e10_1e27_'+string(iso_logt,format='(f4.2)')+'.genx'
      savegen, struct=spc, file=save_file
    endelse

  end      ; end temperature loop

end

;------------------------ function to provide date label -----------------
FUNCTION TODAY
t=systime(0)
day=strmid(t,8,2)
month=strmid(t,4,3)
year=strmid(t,20,4)
s='-'
return,year+s+month+s+day
end
;
;------------------------ fold_spec_resp.pro ---------------------------

;+
; PROJECT:
;     GOES
;
; PURPOSE:
;     Generate GOES responses by folding CHIANTI spectra with wavelength
;     responses of individual satellites.
;
; CALLING SEQUENCE:
;       fold_spec_resp , NSAT [, /PLOTSPEC ]
;
; INPUTS:
;       NSAT = number of GOES satellites
;       Set /PLOTSPEC if you want results plotted as they are derived
;       SECONDARY: handles GOES-R series with 2 detectors per channel
;           0=A1+B1, 1=A2+B1, 2=A1+B2, 3=A2+B2 
;           Set appropriate a_prim, b_prim indices in response structure
;
; OUTPUTS:
;       Individual save files containing temperature responses etc in files
;       idlsave.fit_coeffs_.02_GOES_<SAT> for each of 12 SATs.
;
; PROCEDURE:
;     Calls MAKE_CHIANTI_SPEC
;
; MODIFICATION HISTORY:
;     SW 2005 Jan
;-
;
function gcr_fold_spec_resp, sat, temp, $
  fshort_cor, flong_cor, fshort_pho,  flong_pho, $
  secondary = secondary

  ; get chianti version
  chianti_version, vers
  default, secondary, 0b
  flpho = file_search('.','ch'+vers+'_pho_3e10_1e27_*genx', count = npho)
  flcor = file_search('.','ch'+vers+'_cor_3e10_1e27_*genx', count = ncor)
  fbase = strmid( ssw_strsplit(flcor,'1e27_',/tail), 0,4)
  if npho ne ncor then message,'There must be equal coronal and photospheric temp spectra'


  ltemp = reform( float(  fbase ))
  temp = 10^(ltemp-6)
  rr = goes_get_transfer( sat= sat, /cali,/inte, lamrange=[0,20.], secondary = secondary)

  ; to convert back to the TSC formalism, we note:
  ; - divide by 10^27 which is column EM assumed by CHIANTI
  ; - divide by 1.496e13 ^ 2 to convert to solar distance
  ; no factor for integration over wavelength in Angstroms: unit is per A
  ; multiply by 1.e-3 to convert from ergs/cm^2/s to Watts/cm^2

  ;cvac=1.d-27*1.d-3/((1.496d13)^2) * 1d55
  ; or
  ;cvac = 1.0 / 1.496^2 * 1e-1
  ; or
  cvac = 0.044682432
  ; extract wavelength scale

  ;restgen, file=fl[0],struct=spc

  ; extract transfer curves for GOES

  ; integrate line and continuum contributions and compare

  fshort_pho = fltarr(npho) & flong_pho = fshort_pho
  fshort_cor = fltarr(ncor) & flong_cor = flong_pho
  for i=0, npho-1 do begin
    restgen, file=flpho[i],struct=spc
    ; integrate continuum
    ; angstrom step size is 0.01 Angstrom
    fshort_pho[i]= 0.01 * cvac * total(  rr.tsmw * spc.spectrum )
    flong_pho[i] = 0.01 * cvac * total(  rr.tlmw * spc.spectrum )
    restgen, file=flcor[i],struct=spc
    ; integrate continuum
    fshort_cor[i]= 0.01 * cvac * total(  rr.tsmw * spc.spectrum )
    flong_cor[i] = 0.01 * cvac * total(  rr.tlmw * spc.spectrum )
  end

  ;temp=6.0+0.02*indgen(nf)
  ;return the "true" flux in Watts/m^2 for an em of 1e55
;  IDL> help, {goes_true_flux}
;  % Compiled module: GOES_TRUE_FLUX__DEFINE.
;  ** Structure GOES_TRUE_FLUX, 12 tags, length=2088, data length=2083:
;     DATE            STRING    '27-Jul-20'
;     VERSION         STRING    '9.0.1'
;     METHOD          STRING    'goes_chianti_response'
;     SAT             INT             16
;     A_PRIM          BYTE         0
;     B_PRIM          BYTE         0
;     ALOG10EM        FLOAT           55.0000
;     TEMP_COEF       FLOAT     Array[2]
;     TEMP_MK         FLOAT     Array[101]
;     FLONG_PHO       FLOAT     Array[101]
;     FSHORT_PHO      FLOAT     Array[101]
;     FLONG_COR       FLOAT     Array[101]
;     FSHORT_COR      FLOAT     Array[101]  
  ; result = goes_true_flux( method =  'goes_chianti_response')
  result = {goes_true_flux}
  result.sat = sat
  ; result.secondary = byte( secondary )
  if ((secondary eq 1) or (secondary eq 3)) then result.a_prim = 2b else result.a_prim = 1b
  if (secondary gt 1) then result.b_prim = 2b else result.b_prim = 1b
  result.flong_pho = flong_pho
  result.fshort_pho = fshort_pho
  result.flong_cor = flong_cor
  result.fshort_cor = fshort_cor
  return, result
end



;+
; :Description:
;    Integrate the product of the chianti generated energy spectra with the
;    given wavelength transfer function to obtain the expected
;    irradiance as a function of temperature for the GOES series XRS detectors
;    This is a rewrite of S White's Make_goes_chianti_response. It must be run
;    in a directory where the chianti generated photon spectra reside in the current
;    directory or its sub-directory
;
;
;
; :Keywords:
;    SAT - satellite number 1-17, jul 2020
;    ALL - return the response vs temperature in a structure array for all GOES XRS 
;      these results have been written into goes_chianti_resp.fits
;      Use (goes_chianti_resp_new_table_set, aa_out) to access the response structure, aa_out
;  ** Structure GOES_TRUE_FLUX, 12 tags, length=2088, data length=2083:
;     DATE            STRING    '27-Jul-20'
;     VERSION         STRING    '9.0.1'
;     METHOD          STRING    'goes_chianti_response'
;     SAT             INT             16
;     A_PRIM          BYTE         0
;     B_PRIM          BYTE         0
;     ALOG10EM        FLOAT           55.0000
;     TEMP_COEF       FLOAT     Array[2]
;     TEMP_MK         FLOAT     Array[101]
;     FLONG_PHO       FLOAT     Array[101]
;     FSHORT_PHO      FLOAT     Array[101]
;     FLONG_COR       FLOAT     Array[101]
;     FSHORT_COR      FLOAT     Array[101]  result = goes_true_flux( method =  'goes_chianti_response')
;      
;     SECONDARY: handles GOES-R series with 2 detectors per channel
;        0=A1+B1, 1=A2+B1, 2=A1+B2, 3=A2+B2 
;        Set appropriate a_prim, b_prim indices in response structure
;
; :Author: rschwartz70@gmail.com, 22-jul-2020
; 28-May-2022, Stephen White. Handle primary/secondary detectors correctly for G>=16 (a_prim,b_prim,secondary)
; 
;-
function goes_chianti_response, sat = sat, all = all, secondary = secondary, have_spec=have_spec 

  if not keyword_set(have_spec) then begin
     ; generate spectra
     gcr_generate_spectra        ; coronal
     gcr_generate_spectra, /photospheric
  endif 

  ; fold spectra with GOES responses for each satellite
  ;nsat=15             ; current number of satellites in goes_tf_coeff
  max_sat = goesr_transfer(/max_sat)
  ; GOES-R series need 4 sets of responses for possible combinations of a1,a2,b1,b2
  if keyword_set( all ) then begin
    response = replicate( {goes_true_flux}, 15 + 4*(max_sat-15))
    for isat = 1, 15 + 4*(max_sat-15) do begin
      this_sat = isat le 15 ? isat : 16 + (isat - 16)/4 
      if (this_sat gt 15) then secondary = (isat-16) mod 4 else secondary=0 ; 4 values per GOES-R sat
      print, 'Response for GOES ',strtrim( this_sat, 2 ),' / ',strtrim(secondary,2) 
      response[ isat - 1] = gcr_fold_spec_resp( this_sat, temp, $
        fshort_cor, flong_cor, fshort_pho, flong_pho, secondary = secondary) 
    endfor
    
  endif else $
    response = gcr_fold_spec_resp( sat, temp, $
       fshort_cor, flong_cor, fshort_pho, flong_pho, secondary = secondary)

  chianti_version, vers
  ; fill in other entries
  response.date=today()
  response.version=vers[0]
  response.method='goes_chianti_response'
  response.alog10em=55.0
  response.temp_coef=[10.,0.02]
  response.temp_mk=10.^(0.02*indgen(101))

  print,"To write FITS file: mwrfits,response,'goes_chianti_resp_"+vers+".fits'"
  print,"Copy to 'goes_chianti_response_latest.fits' for use with goes_chianti_resp_new_table_set"

  return, response
end
