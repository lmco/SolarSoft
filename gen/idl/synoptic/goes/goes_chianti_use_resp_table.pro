;+
; :Description:
;    Use the latest formulated response tables including the responses
;    for GOES1-17 to interpolate for temperature or emission measure from the measured true fluxes or conversely
;    to predict the net true fluxes based upon input temperatures and emission measures
; :Params:
;    input - a 2xN or Nx2 arrary of long and short channel fluxes (true fluxes) in Watts/M^2
;    or (if FLUX_INPUT is set to 0) a 2xN or Nx2 array of Emission Measure (1e49 cm-3) and Temperature(TEMP)
;    in MegaKelvin
;    output - for FLUX_INPUT of 1 (default) returns EM and TEMP in units described for input
;    and for FLUX_INPUT of 0 returns the long and short channels in Watts / M^2 in the same shape as
;    the input
;
; :Keywords:
;    SAT - GOES XRS satellite - 1-17 as of 14-jul-2020
;    FLUX_INPUT - logical, 0 or 1, if set then the input is in true flux in Watts/M^2 and 
;      the output will be emission measure in units
;      of 1e49/cm^3 and temperature in MegaKelvin
;    SECONDARY - values 0,1,2,3 indicate A1+B1, A2+B1, A1+B2, A2+B2 detector combos for GOES-R
;    PHOTOSPHERIC - 1 or 0, if set, use response for photospheric abundances
;    
; :Example:
;    IDL> help, input & goes_chianti_use_resp_table, input, out, sat=15, flux_input = 1
;    INPUT           FLOAT     = Array[1, 2]
;    IDL> print, input
;    1.00000e-006
;    3.00000e-007
;    IDL> print, out
;    0.0299670
;    21.2304
;    IDL> input = reform( reproduce( [1.e-6,3e-7],3))
;    IDL> help, input
;    INPUT           FLOAT     = Array[2, 3]
;    IDL> help, input & goes_chianti_use_resp_table, input, out, sat=15, flux_input = 1
;    INPUT           FLOAT     = Array[2, 3]
;    IDL> out
;    0.029967025       21.230410
;    0.029967025       21.230410
;    0.029967025       21.230410
;    IDL> help, input & goes_chianti_use_resp_table, transpose(input), out, sat=15, flux_input = 1
;    INPUT           FLOAT     = Array[2, 3]
;    IDL> out
;    0.029967025     0.029967025     0.029967025
;    21.230410       21.230410       21.230410
;    
;    Now take the output in Em(*1e49) and Temp in MK and use that as the input
;    by setting FLUX_INPUT to 0
;    IDL> help, out & goes_chianti_use_resp_table, out, input_recovered, sat=15, flux_input = 0
;    OUT             FLOAT     = Array[2, 3]
;    IDL> print, input
;    1.00000e-006 3.00000e-007
;    1.00000e-006 3.00000e-007
;    1.00000e-006 3.00000e-007
;    IDL> print, input_recovered
;    1.00000e-006 2.99972e-007
;    1.00000e-006 2.99972e-007
;    1.00000e-006 2.99972e-007
;    
; :Hidden_file: Requires goes_chianti_resp.fits produced by goes_chianti_respons.pro
;  This file contains the pregenerated responses for default coronal and photospheric ion abundances
;  using Chianti version 9.0.1 This file is in either the working directory or in ssw/gen/idl/synoptic/goes
;  accessed through GOES_CHIANTI_RESP_NEW_TABLE_SET
; :Author: 14-jul-2020, rschwartz70@gmail.com
; 5-sep-2020, added goesr fudge of 1.32 for scale16 and observed keyword
; 8-sep-2020, expanded documentation and environment variable control of SCALE16
; 21-sep-2020, changed fudge to 1.4 as it's believed from the ratio 3.5/2.5
; 25-apr-2022, SW: removed SCALE16, not needed now that we understand that
;                  GOES 13-15 assumed incorrect calibration for 0.5-4.0
; 27-May-2022, SW. Change setting of isat to include secondary keyword for sat > 15 (includes detector info)                
;-
pro goes_chianti_use_resp_table, input_in, output, sat=sat, flux_input = flux_input, $
  secondary = secondary, photospheric = photospheric

  default, photospheric, 0
  default, flux_input, 1 ; goes fluxes, 2xN are input values, or detected N x 2 if N gt 2
  default, sat, 15
  default, secondary, 0

  input = input_in
  siz_in = size(/str, input )
  flip   = siz_in.dimensions[0] gt 2
  n2   = siz_in.n_elements eq 2
  input  = flip ? transpose( input ) : input
  ;Put the input into the expected form
  if flux_input then begin
    ratio = n2 ? f_div( input[1], input[0] ) : f_div( input[1,*], input[0,*] )
    long  = reform( input[0,*] )
  endif else begin
    em_in   = n2 ? input[0] :input[0,*]
    temp = n2 ? input[1] : input[1,*]
  endelse

  common goes_chianti_resp_com, aa, slr

;    IDL> help, aa
;    AA              STRUCT    = -> GOES_TRUE_FLUX Array[17]
;    IDL> help, aa,/st
;  ** Structure GOES_TRUE_FLUX, 12 tags, length=2088, data length=2083:
;     DATE            STRING    '27-Jul-20'
;     VERSION         STRING    '9.0.1'
;     METHOD          STRING    'goes_chianti_response'
;     SAT             INT             16
;     SECONDARY       BYTE         0
;     ALOG10EM        FLOAT           55.0000
;     TEMP_COEF       FLOAT     Array[2]
;     TEMP_MK         FLOAT     Array[101]
;     FLONG_PHO       FLOAT     Array[101]
;     FSHORT_PHO      FLOAT     Array[101]
;     FLONG_COR       FLOAT     Array[101]
;     FSHORT_COR      FLOAT     Array[101]  result = goes_true_flux( method =  'goes_chianti_response')
;    
  ;Check to see if the precomputed response tables have been loaded
  ;If not load the data file and compute the ratio table, SLR SHORT LONG RATIO
  goes_chianti_resp_new_table_set, aa ; reads the full response set - all 23 arrays 
  ;convert the satellite number into an index: 16+ needs secondary keyword 
  isat  = sat le 15 ? sat-1 : 15+4*(sat-16)+secondary

  ;FLUXES IN WATTS/M^2 are the input
  if flux_input then begin
    dim   = size(/dim, slr )
    tbl   = aa[isat]
    table_to_response_em = 10.0^(49.-tbl.alog10em)
; Interpolate the ratio to get the table index
    index = interpol(/spl, findgen( dim[0]), slr[*,isat, photospheric], ratio )
; Interpolate the index to get the temperature
    temp  = interpol(/spl, tbl.temp_mk, findgen( dim[0]), index)
    ;Now that we have the temp, find the em and scale to 1e49 cm-3
; Interpolate the index to get the emission measure
    em_table = ( photospheric ? tbl.flong_pho : tbl.flong_cor ) * table_to_response_em
; Use the input long channel data to scale the interpolated EM_table values
    em    = long / interpol( /spl, em_table, findgen(101), index)
    output = float( input*0.0 )
; Shape and load the output array
    if n2 then output = reform( [em,temp], size( input_in,/dim)) else begin
      output[ 0, *] = em
      output[ 1, *] = temp
    endelse
    output = flip ? transpose( output ) : output
  endif else begin ; em and temp entered to return expected fluxes
    dim   = size(/dim, slr )
    tbl   = aa[isat]
    table_to_response_em = 10.0^(49.-tbl.alog10em)
    emscl = em_in * table_to_response_em ;(expect 1e-6)
    ;Get the precomputed long and short channel True fluxes for 
    longtbl  = photospheric ? tbl.flong_pho : tbl.flong_cor
    shorttbl = photospheric ? tbl.fshort_pho : tbl.fshort_cor
    ;Interpolate the long and short response tables to find the values
    ;for the temperature input
    ;Then scale the values based on the input emission measure which is in units
    ;of 1e49cm-3 and then tables in units of 1e55cm-3
    long  = emscl * interpol( /spl, longtbl, tbl.temp_mk, temp )
    short = emscl * interpol( /spl, shorttbl, tbl.temp_mk, temp)
    output = float( input*0.0 )

    if n2 then output = reform( [long, short], size( input_in,/dim)) else begin
      output[ 0, *] = long
      output[ 1, *] = short
    endelse
    output = flip ? transpose( output ) : output


  endelse
end
