;+
; :Description:
;    GOES16 & GOES17 have primary and secondary detectors to extend the dynamic range. During intense
;    flares both the primary and secondary fluxes may be reported and this routine matches the data
;    with the correct response.  This will have no effect on GOES1-15 and where the SECONDARY keyword input
;    is not used. This code MANAGES this difference, otherwise GOES_CHIANTI_USE_RESP_TABLE could be called directly
;
; :Params:
;    input_in - 2 x N or N x 2 array of GOES fluxes (irradiance) or emission measure temperature pairs.
;    if fluxes, B (Long) channel is first and A (Short) second. Units, Watts/meter^2
;    if EM/T pairs - Emission measure first in units of 1e49 cm-3 and Temp in MegaKelvin
;    output
;
; :Keywords:
;    SAT - GOES XRS satellite - 1-17 as of 14-jul-2020
;    FLUX_INPUT - logical, 0 or 1, if set then the input is in true flux in Watts/M^2 and 
;      the output will be emission measure in units
;      of 1e49/cm^3 and temperature in MegaKelvin
;    A_PRIM - byte array: for 1 sec data, 1s and 2s indicating which detector is primary for channel a
;             for 1-min data, copy of xrs_primary_chan - see Janet's email
;    B_PRIM - byte array: for 1 sec data, 1s and 2s indicating which detector is primary for channel b
;             for 1-min data, array of 0b
;    PHOTOSPHERIC - 1 or 0, if set, use response for photospheric abundances
;
; :Author: rschwartz70@gmail.com, 17-jul-2020
; Modifications:
; 26-May-2022, Kim. Replaced secondary keyword with a_prim and b_prim keywords. 
; 27-May-2022, SW: replaced "secondary" logic with looping through 4 GOES-R options
; 31-May-2022, SW: 1-minute data don't carry a_prim info, use thresholds
;-
pro goes_chianti_use_resp_table_manage, input_in, output, sat=sat, flux_input = flux_input, $
  a_prim=a_prim, b_prim=b_prim, photospheric = photospheric

  ninput = n_elements( input_in ) / 2 ; 2 entries per input, long & short or EM & temperature
  nscnd  = n_elements( a_prim )
  if ninput ne nscnd and nscnd ne 1 then message,'Something wrong: primary channel designators wrong size.'

  ; Here we keep track of the indices that belong to the primary and secondary detectors respectively
  ; loop through the options for GOES-R
  output = input_in * 0.0
  pp=where((a_prim ne 2b) and (b_prim ne 2b), npp)
  if npp ge 1 then begin
     goes_chianti_use_resp_table, input_in[*,pp], output_tst, sat=sat, flux_input = flux_input, $
       secondary=0, photospheric = photospheric
     output[*,pp] = output_tst
  endif
  qq=where((a_prim eq 2b) and (b_prim ne 2b), nqq)
  if nqq ge 1 then begin
     goes_chianti_use_resp_table, input_in[*,qq], output_tst, sat=sat, flux_input = flux_input, $
       secondary=1, photospheric = photospheric
     output[*,qq] = output_tst
  endif
  rr=where((a_prim ne 2b) and (b_prim eq 2b), nrr)
  if nrr ge 1 then begin
     goes_chianti_use_resp_table, input_in[*,rr], output_tst, sat=sat, flux_input = flux_input, $
       secondary=2, photospheric = photospheric
     output[*,rr] = output_tst
  endif
  ss=where((a_prim eq 2b) and (b_prim eq 2b), nss)
  if nss ge 1 then begin
     goes_chianti_use_resp_table, input_in[*,ss], output_tst, sat=sat, flux_input = flux_input, $
       secondary=3, photospheric = photospheric
     output[*,ss] = output_tst
  endif
  
  ; if (npp ne ninput) then 
  print,'Found GOES-R detector combinations 1+1=',strtrim(string(npp),2),' 2+1=',strtrim(string(nqq),2),' 1+2=',strtrim(string(nrr),2),' 2+2=',strtrim(string(nss),2)

end
