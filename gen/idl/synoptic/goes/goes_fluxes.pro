;+
; Project     : SSW
;
; Routine: GOES_FLUXES, now replacing GOES_FLUX49
;
; Purpose: 
;  This is the new routine used to compute the expected Long (B) and Short (A) channel fluxes
;  (irradiances) given the temperaure and emission measure. The units of irradiance are
;  Watts/M^2 and the inputs are in units of MegaKelvin and Solar Emission Measure in 1e49cm^(-3).
;  It is used with GOES1-17 and uses computations based on CHIANTI 9.0.1
;  It has supplanted  GOES_FLUX49 which used CHIANTI 7.1. NB, these results are not sensitive to the
;  choice of the Chianti distribution epoch but have been updated for consistency as new GRS
;  come online
;  Goes_flux49 will not be modified going forward. 
;
; Category    : GOES
;
; Explanation : 
;  This procedure uses tables found in goes_chianti_use_resp_table_manage obtained by convolving
;  the transfer function with the Chianti synthetic spectra spanning sensitive detector range
;  for 101 temperatures from 1-100 MK
; 
;
; Use         : GOES_FLUXES, Temperature, Emission_meas, Flong, Fshort
;
; Inputs      :
;		Temperature - temperature in MegaKelvin
;		Emission_meas- Emission measure in units of 1e49 cm^-3
;
; Opt. Inputs : None
;
; Outputs     : 
;  Flong - flux in Watts/meter^2 in GOES 1-8 Angstrom channel
;	 Fshort- flux in Watts/meter^2 in GOES 0.5-4 Angstrom channel
;
; Opt. Outputs: None
;
; Keywords    :
;   ABUND - 3 choices
;     0 - Use table made using Chianti Coronal Abundance
;     1 - Use table made using Chianti Photospheric Abundance
;     2 - Obsolete, uses table made using MEWE spectra, not maintained. Here for old time's
;     sake.  Should not be used
;   SATELLITE- GOES satellite number
;   PHOTOSPHERIC - if set will override ABUND keyword and will use photospheric abundances
;   DATE- Time of observation in ANYTIM format, ONLY needed for GOES6 which changed
;    its long wavelength averaged transfer constant used in reporting measured
;    current as Watts/meter^2
;   TRUE_FLUX - if set, scaling factors are not applied. Only the given transfer function
;    has been used.  New, July 2020, Mewe implementation, ABUND ==2, doesn't support TRUE_FLUX, unsupported
;   NEW_TABLE - logical, defaults to 1, setting this to 0 for SAT le 15, gives you the results from
;    goes_flux49. Really only here if for some reason you desperately want to use the CHIANTI 7.1 results. 
;    It should normally be left alone with its default of 1.
;--- NOTE - ONLY CONSIDER SETTING A_PRIM, B_PRIM OR SECONDARY IF YOU ARE AT X FLARE LEVELS
;   SECONDARY - for GOES16+ there are smaller aperture secondary detectors selected for both channels by this 
;    keyword. Equivalent to setting A_PRIM=2B & B_PRIM=2B; outputs will be very slightly different.
;   A_PRIM, B_PRIM: these arrays specify in detail which detectors to use for GOES 16+. They are byte arrays of 1s
;    (large area) and 2s (small area) indicating which detector is primary for channels A (0.5-4.0) and B (1-8), 
;    respectively. DEFAULT is 1 (large area); 2 is appropriate for large (X) flares (A > 1.e-5, B > 1.e-4).
;    If just one value is given for the keyword, it is assumed to apply for all data.
;   ERROR - if set then input is problematic
;
; Calls       : GOES_FLUX49 or GOES_TEM (NOW GOES_TEM_OLD)
;
; Common      : None
;
; Restrictions: Temperature between 1 and 98 MegaKelvin,
;
; Side effects: None.
;
; Prev. Hist  : VERSION 1, RAS, 30-JAN-1997
;
; Modified    : 7-apr-2008, ras, updated to provide inverse
;	 operations to GOES_TEM and uses same databases with same basic meanings for parameters.
;	 Differences are minor, temperature - tempr, emission_meas - emis, satellite - sat
;	 flong and fshort form yclean - avback.  Units are the same for flux, temperature,
;	 emission measure
; HISTORY: 4-apr-2008, richard.schwartz@nasa.gov,
; 22-apr-2011, richard.schwartz@nasa.gov, changed goes6 date to 28-jun-1983
; 3-jul-2020, RAS, TRUE_FLUX keyword implemented
; 14-jul-2020,  Richard Schwartz,  implement new GOES response based on Chianti v9.0.1 and
;   for the first time including the transfer functions for GOES16 and 17
; 06-oct-2020, RAS, update documentation
; 27-jul-2022, SMW: adapted for use of a_prim, b_prim detector keywords for GOES 16+
;
;
;-
;==============================================================================
pro goes_fluxes, temperature, emission_meas, flong, fshort, $
  satellite=satellite, date=date, abund = abund, true_flux = true_flux, $
  new_table = new_table, photospheric = photospheric, a_prim=a_prim, b_prim=b_prim, $
  secondary = secondary, error=error

  flong = 0.0
  fshort= 0.0
  error = 1
  default, abund, 0 ;coronal chianti
  abund = (abund >0 )< 2
  default, photospheric, 0
  if photospheric then abund = 1
  if abund eq 1 then photospheric = 1
  default, new_table, 1
  default, true_flux, 1 ;true_flux is the default for the old tables and new tables
  ;true_flux means no ad_hoc scaling factors, just based on the transfer functions
  new_table = satellite ge 16 ? 1 : new_table ;only the new_table using Chianti 9.0.1 for 16+

  case 1 of
    new_table: begin
      ;TRUE_FLUX is the default and only method used for the NEW_TABLE other than
      ;the GOES6 exception below
      emtemp = transpose( [[ emission_meas[*]], [temperature[*] ]])
      ; manage 2 detectors on GOES 16+
      nval=n_elements(emission_meas) & atmp=bytarr(nval)+1b & btmp=bytarr(nval)+1b ; default is detector 1
      if keyword_set(secondary) then begin & atmp[*]=2b & btmp[*]=2b & end ; convenient way to set both
      if keyword_set(a_prim) then begin  ; supercedes /SECONDARY
         if (n_elements(a_prim) eq 1) then atmp[*]=byte(a_prim) else atmp=a_prim 
      endif
      if keyword_set(b_prim) then begin  ; supercedes /SECONDARY
         if (n_elements(b_prim) eq 1) then btmp[*]=byte(b_prim) else btmp=b_prim 
      endif
      goes_chianti_use_resp_table_manage, emtemp, flfs, sat=satellite, flux_input = 0, $
        a_prim = atmp, b_prim = btmp, photospheric = photospheric
      ;Results are in FLFS array
      flong = reform( flfs[0,*])
      fshort = reform( flfs[1,*])
      ;need guidance from NOAA on this GOES6 scaling
      if anytim(fcheck(date, 1.4160960e+008),/sec) lt 1.4160960e+008 $
        and satellite eq 6 then flong = flong / (4.43/5.32)
      end
    abund le 1:	goes_flux49, temperature, emission_meas, flong, fshort, $
      sat=satellite, date=date, photospheric=abund, true_flux = true_flux, error=error
    else: begin
      goes_tem_old, flong, fshort, temperature, emission_meas, satellite=satellite, date=date
      error = 0
    end
  endcase

end
