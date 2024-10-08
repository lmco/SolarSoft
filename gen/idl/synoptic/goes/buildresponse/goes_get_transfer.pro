;+
; :Description:
;    Returns the transfer functions for GOES 1-15 extracted from
;    make_goes_chianti_response or reads the response file for
;    GOES16+(calls goesr_transfer() )
;
; :Keywords:
;    sat - satellite 1-17 (22-jul-2020)
;    goes6date - for scaling cutoff date (28-jun-1983) only used with GOES6
;    secondary - return calibration for secondary detectors (16/17 only)
;        0 = A1+B1, 1 = A2+B1, 2 = A1+B2, 3 = A2+B2
;    interpolate - interpolate transfer functions to fine bins, default is 2000 equally spaced bins
;      see goes_interpolate_transfer() for details on keywords passed by _extra
;    calibrate   - divide transfer arrays by gbar's
;    _extra
;
; :Author: rschwartz70@gmail.com, 22-jul-2020
;          SMW, 2022 Apr: corrected G-bar for GOES 13-15, put correct GOES 13 responses
;                         in place of dummy copy of GOES 14 response
;-
function goes_get_transfer, sat = sat, goes6date = goes6date, secondary = secondary, $
 interpolate = interpolate, calibrate = calibrate, _extra = _extra
  
  default, sat, 15
  max_sat = goesr_transfer( /max_sat )
  default, calibrate, 0 ;if set, divide tf's by normalization aka gbar
  if sat ge 16 then begin
;    ** Structure <1660b580>, 10 tags, length=6920, data length=6914, refs=1:
;    SAT             INT             16
;    TRANSFER        DOUBLE    Array[5, 172]
;    GB_A1           FLOAT      9.61500e-006
;    GB_A2           FLOAT      5.06362e-007
;    GB_B1           FLOAT      1.46900e-005
;    GB_B2           FLOAT      7.76169e-007
;    AREA_A1         FLOAT      9.61500e-006
;    AREA_A2         FLOAT      5.06362e-007
;    AREA_B1         FLOAT      1.46900e-005
;    AREA_B2         FLOAT      7.76169e-007
   r16 = goesr_transfer(sat)
   default, secondary, 0 ;if set, use transfer for small aperture detectors
   ; parse secondary 
   wsm = r16.transfer[0,*]
   wlm = wsm
   if (secondary eq 0) then begin
      tsm = r16.transfer[1,*] & tlm = r16.transfer[3,*]
      gbshort = r16.gb_a1 & gblong  = r16.gb_b1
   endif else if (secondary eq 1) then begin
      tsm = r16.transfer[2,*] & tlm = r16.transfer[3,*]
      gbshort = r16.gb_a2 & gblong  = r16.gb_b1
   endif else if (secondary eq 2) then begin
      tsm = r16.transfer[1,*] & tlm = r16.transfer[4,*]
      gbshort = r16.gb_a1 & gblong  = r16.gb_b2
   endif else if (secondary eq 3) then begin
      tsm = r16.transfer[2,*] & tlm = r16.transfer[4,*]
      gbshort = r16.gb_a2 & gblong  = r16.gb_b2
   endif

   if calibrate then begin
    tsm = tsm/ gbshort
    tlm = tlm/ gblong
   endif
   result = { tsm: tsm, tlm: tlm, wsm: wsm, wlm: wlm, gbshort: gbshort, $
     gblong: gblong, calibrated: calibrate, sat: sat}
   
   if keyword_set( interpolate ) then result = goes_interpolate_transfer( result, _extra = _extra )
    return, result
  endif ; 
  ;End of block supporting GOESR, 16/17+
  ;
  nsat=15

  ;  G-bar values in units of Amp/(Watt/meter^2) for all GOES satellites:
  ; integration procedure for gbars, need to tiptoe around jumps
  ; sort ws,ts,wl,tl into wavelength before applying following
  ; gbars=int_tabulated(ws[0:3],ts[0:3],/double)+int_tabulated(ws[4:27],ts[4:27],/double)+int_tabulated(ws[28:50],ts[28:50],/double)
  ; gbarl=int_tabulated(wl[0:19],tl[0:19],/double)+int_tabulated(wl[20:51],tl[20:51],/double)
  ; gbshort=gbars/2.5 & gblong=gbarl/7., assumes averaging over 0.5-3.0 and 1-8 A
  ; values for GOES 15 calculated from these formulae, no official values

  ; legacy values: used incorrect scaling for 13-15 gbshort - 2022 Apr
  ; gbshort = 1e-5*[1.27,1.25,1.25,1.73,1.74,1.74,1.68,1.580,1.607,1.631,1.608,1.595,1.560,1.560,1.593]
  ; gblong = 1e-6*[4.09,3.98,3.98,4.56,4.84,5.32,4.48,4.165,3.990,3.824,4.377,4.090,4.167,4.167,3.991]
  ; gbshort/long get redefined: make default values to re-use at end so only in one place
  gbarshort = 1e-5*[1.27,1.25,1.25,1.73,1.74,1.74,1.68,1.580,1.607,1.631,1.608,1.595,1.155,1.117,1.141]
  ; GOES 13 gblong was wrong previously - 2022 Apr
  gbarlong = 1e-6*[4.09,3.98,3.98,4.56,4.84,5.32,4.48,4.165,3.990,3.824,4.377,4.090,3.702,4.167,3.991]
  gbshort=gbarshort & gblong=gbarlong
  if anytim(fcheck(date,2e8),/sec) ge 1.416096e8 then gblong[5]=4.43e-6      ; Before & after for GOES-6
  
  ;  Transfer function coefficients for all GOES satellites:
   wsm=dblarr(55, nsat) & wlm=wsm & tsm=wsm & tlm=wsm

  ;  Transfer function measurements for GOES-1 through GOES-5:
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35839,.35841,2.5869,2.5871]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.869,3.871]
  ts= 1.e-6*[ .162, .621, 1.38, 1.01, 1.8, 2.87, 2.03, 5.61, 7.73,       $
    9.24,  11.0, 12.9, 14.7, 16.3, 17.1, 18.0, 18.6, 18.9, 19.0,         $
    18.8, 18.5, 18.0, 17.1, 16.4,  15.1, 11.3, 11.2, 11.0, 10.7, 10.4,   $
    9.89, 9.36, 8.77, 8.14, 7.5, 6.68, 5.54, 4.38, 3.25, 2.39,1.70, 1.17,$
    .781, .233, .0539, .00131, .00001, 1.79, .789, 14.5, 11.3]
  tl= 1.e-6*[.021, .140, .418, .887, 1.54, 2.34, 3.24, 4.11,             $
    4.87, 5.49, 5.92, 6.18, 6.29, 6.31, 6.25, 6.14, 6.01, 5.85, 5.68,    $
    4.02, 4.12, 4.20, 4.24, 4.24, 4.19, 4.09, 3.96, 3.81, 3.62, 3.42,    $
    3.21, 2.99, 2.54, 2.07, 1.66, 1.31, .992, .732, .527, .368, .249,    $
    .163, .102, .0624, .0369, .0210, .00416, .00068, .00009, .00001,     $
    5.63, 3.92]
  v=where(abs(ws-0.7) gt .01) & ws=ws[v] & ts=ts[v]    ; Correction by RJT
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  for ix_nsat = 0,4 do begin
    wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl   ; Load array
  endfor

  ;  Transfer function measurements for GOES-6:
  ws=[.1+.1*findgen(35),3.6+.2*findgen(15),.35839,.35841,2.5869,2.5871]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.869,3.871]
  ts= [1.25e-7,6.20e-7, $
    1.33e-6,9.94e-7,1.79e-6,2.88e-6,4.24e-6,5.82e-6,7.56e-6,9.40e-6, $
    1.13e-5,1.30e-5,1.46e-5,1.60e-5,1.68e-5,1.77e-5,1.83e-5,1.85e-5, $
    1.86e-5,1.84e-5,1.80e-5,1.76e-5,1.67e-5,1.61e-5,1.47e-5,1.10e-5, $
    1.09e-5,1.06e-5,1.03e-5,9.92e-6,9.47e-6,8.93e-6,8.39e-6,7.77e-6, $
    7.18e-6,6.49e-6,5.27e-6,4.12e-6,3.11e-6,2.27e-6,1.59e-6,1.08e-6, $
    7.07e-7,5.06e-7,3.06e-7,1.74e-7,1.10e-7,4.60e-8,3.70e-8,2.80e-8, $
    0.97e-6*[1.79,.789,14.5,11.3]]
  tl= [1.99e-8,1.42e-7, $
    4.27e-7,9.21e-7,1.57e-6,2.37e-6,3.26e-6,4.15e-6,4.95e-6,5.58e-6, $
    6.04e-6,6.31e-6,6.43e-6,6.45e-6,6.40e-6,6.29e-6,6.16e-6,6.00e-6, $
    5.83e-6,4.09e-6,4.22e-6,4.31e-6,4.35e-6,4.35e-6,4.30e-6,4.20e-6, $
    4.08e-6,3.92e-6,3.74e-6,3.54e-6,3.32e-6,3.11e-6,2.65e-6,2.20e-6, $
    1.77e-6,1.39e-6,1.06e-6,7.86e-7,5.67e-7,4.00e-7,2.74e-7,1.79e-7, $
    1.15e-7,7.07e-8,4.22e-8,2.43e-8,4.99e-9,8.3e-10,1.1e-10,1.1e-11, $
    5.63e-6, 3.92e-6]
  v=where(ws lt 6.1)           & ws=ws[v] & ts=ts[v]   ; Correction by RJT
  v=where(abs(wl-3.87) gt .01) & wl=wl[v] & tl=tl[v]   ; Correction by RJT
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array

  ;  Transfer function measurements for GOES-7:
  ws=[.1+.1*findgen(35),3.6+.2*findgen(15),.35839,.35841,2.5869,2.5871]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.869,3.871]
  ts= [1.23e-7,6.12e-7, $
    1.31e-6,9.80e-7,1.77e-6,2.84e-6,4.18e-6,5.74e-6,7.46e-6,9.27e-6, $
    1.11e-5,1.29e-5,1.45e-5,1.58e-5,1.66e-5,1.75e-5,1.81e-5,1.83e-5, $
    1.83e-5,1.82e-5,1.78e-5,1.74e-5,1.64e-5,1.59e-5,1.46e-5,1.09e-5, $
    1.08e-5,1.04e-5,1.02e-5,9.81e-6,9.37e-6,8.83e-6,8.30e-6,7.68e-6, $
    7.11e-6,6.43e-6,5.22e-6,4.08e-6,3.09e-6,2.26e-6,1.58e-6,1.08e-6, $
    7.04e-7,5.04e-7,3.06e-7,1.74e-7,1.10e-7,4.61e-8,3.70e-8,2.80e-8, $
    0.95e-6*[1.79,.789,14.5,11.3]]
  tl= [2.09e-8,1.50e-7, $
    4.48e-7,9.67e-7,1.64e-6,2.49e-6,3.42e-6,4.35e-6,5.19e-6,5.85e-6, $
    6.32e-6,6.60e-6,6.72e-6,6.73e-6,6.67e-6,6.54e-6,6.39e-6,6.22e-6, $
    6.03e-6,4.22e-6,4.34e-6,4.42e-6,4.45e-6,4.43e-6,4.35e-6,4.24e-6, $
    4.10e-6,3.92e-6,3.72e-6,3.49e-6,3.25e-6,3.03e-6,2.54e-6,2.08e-6, $
    1.64e-6,1.26e-6,9.33e-7,6.67e-7,4.73e-7,3.24e-7,2.14e-7,1.34e-7, $
    8.32e-8,4.90e-8,2.79e-8,1.53e-8,2.72e-9,3.8e-10,4.3e-11,3.4e-11, $
    [5.63e-6, 3.92e-6]*1.05]
  v=where(ws lt 6.1)           & ws=ws[v] & ts=ts[v]   ; Correction by RJT
  v=where(abs(wl-16.0) gt .01) & wl=wl[v] & tl=tl[v]   ; Correction by RJT
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array

  ;  Transfer function measurements for GOES-8:
  ws=[.1+.1*findgen(36),3.8+.2*findgen(14)]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4)]
  ts= [1.19E-7, 5.90E-7, $
    1.27E-6, 9.47E-7, 1.71E-6, 2.74E-6, 4.04E-6, 5.54E-6, 7.19E-6, 8.94E-6, $
    1.07E-5, 1.24E-5, 1.39E-5, 1.52E-5, 1.60E-5, 1.68E-5, 1.74E-5, 1.76E-5, $
    1.76E-5, 1.74E-5, 1.70E-5, 1.66E-5, 1.57E-5, 1.51E-5, 1.38E-5, 1.03E-5, $
    1.02E-5, 9.84E-6, 9.58E-6, 9.22E-6, 8.78E-6, 8.25E-6, 7.72E-6, 7.13E-6, $
    6.57E-6, 5.92E-6, 4.76E-6, 3.69E-6, 2.76E-6, 2.00E-6, 1.38E-6, 9.28E-7, $
    5.97E-7, 3.58E-7, 2.17E-7, 1.23E-7, 6.62E-8, 3.55E-8, 1.62E-8, 7.39E-9]
  tl= [1.82E-8, 1.31E-7, $
    3.92E-7, 8.46E-7, 1.44E-6, 2.18E-6, 3.00E-6, 3.81E-6, 4.55E-6, 5.13E-6, $
    5.55E-6, 5.80E-6, 5.92E-6, 5.94E-6, 5.89E-6, 5.80E-6, 5.69E-6, 5.55E-6, $
    5.40E-6, 3.79E-6, 3.92E-6, 4.01E-6, 4.06E-6, 4.06E-6, 4.02E-6, 3.94E-6, $
    3.84E-6, 3.70E-6, 3.54E-6, 3.36E-6, 3.16E-6, 2.97E-6, 2.56E-6, 2.15E-6, $
    1.74E-6, 1.39E-6, 1.07E-6, 8.06E-7, 5.90E-7, 4.24E-7, 2.95E-7, 1.97E-7, $
    1.29E-7, 8.16E-8, 4.99E-8, 2.96E-8, 6.55E-9, 1.19E-9, 1.8E-10, 1.9E-11]
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array

  ;  Transfer function measurements for GOES-9:
  ws=[.1+.1*findgen(36),3.8+.2*findgen(14)]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4)]
  ts= [1.19E-7, 5.89E-7, $
    1.26E-6, 9.45E-7, 1.70E-6, 2.74E-6, 4.03E-6, 5.53E-6, 7.18E-6, 8.93E-6, $
    1.07E-5, 1.24E-5, 1.39E-5, 1.52E-5, 1.60E-5, 1.68E-5, 1.74E-5, 1.76E-5, $
    1.76E-5, 1.75E-5, 1.71E-5, 1.67E-5, 1.58E-5, 1.52E-5, 1.40E-5, 1.04E-5, $
    1.03E-5, 9.98E-6, 9.73E-6, 9.38E-6, 8.95E-6, 8.43E-6, 7.91E-6, 7.32E-6, $
    6.77E-6, 6.11E-6, 4.95E-6, 3.86E-6, 2.91E-6, 2.12E-6, 1.48E-6, 1.01E-6, $
    6.55E-7, 3.98E-7, 2.44E-7, 1.41E-7, 7.67E-8, 4.18E-8, 1.95E-8, 9.06E-9]
  tl= [1.74E-8, 1.24E-7, $
    3.73E-7, 8.05E-7, 1.37E-6, 2.07E-6, 2.85E-6, 3.63E-6, 4.33E-6, 4.89E-6, $
    5.29E-6, 5.53E-6, 5.64E-6, 5.66E-6, 5.62E-6, 5.53E-6, 5.42E-6, 5.29E-6, $
    5.15E-6, 3.62E-6, 3.74E-6, 3.83E-6, 3.88E-6, 3.88E-6, 3.85E-6, 3.78E-6, $
    3.68E-6, 3.55E-6, 3.40E-6, 3.23E-6, 3.04E-6, 2.86E-6, 2.47E-6, 2.08E-6, $
    1.69E-6, 1.35E-6, 1.04E-6, 7.91E-7, 5.82E-7, 4.20E-7, 2.94E-7, 1.98E-7, $
    1.30E-7, 8.27E-8, 5.09E-8, 3.04E-8, 6.89E-9, 1.28E-9, 1.9E-10, 2.2E-11 ]
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array

  ;  Transfer function measurements for GOES-10:
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35798,.35801,2.5889,2.5901]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.869,3.8701]
  ts= [ $
    1.21e-7, 6.01e-7, 1.29e-6, 9.63e-7, 1.73e-6, 2.79e-6, 4.10e-6, 5.64e-6, $
    7.32e-6, 9.10e-6, 1.09e-5, 1.26e-5, 1.42e-5, 1.55e-5, 1.62e-5, 1.71e-5, $
    1.77e-5, 1.79e-5, 1.79e-5, 1.78e-5, 1.73e-5, 1.70e-5, 1.60e-5, 1.55e-5, $
    1.42e-5, 1.06e-5, 1.04e-5, 1.01e-5, 9.83e-6, 9.47e-6, 9.02e-6,          $
    8.49e-6, 7.96e-6, 7.36e-6, 6.79e-6, 6.12e-6, 4.94e-6, 3.85e-6, 2.85e-6, $
    2.10e-6, 1.46e-6, 9.84e-7, 6.37e-7, 1.81e-7, 3.92e-8, 8.17e-10,4.24e-12,$
    1.62e-6, 7.30e-7, 1.37e-5, 1.06e-5]
  tl= [1.76e-8, 1.26e-7, $
    3.77e-7, 8.14e-7, 1.38e-6, 2.09e-6, 2.88e-6, 3.67e-6, 4.37e-6, 4.93e-6, $
    5.33e-6, 5.56e-6, 5.67e-6, 5.68e-6, 5.63e-6, 5.53e-6, 5.41e-6, 5.26e-6, $
    5.11e-6, 3.58e-6, 3.68e-6, 3.76e-6, 3.78e-6, 3.77e-6, 3.71e-6, 3.62e-6, $
    3.51e-6, 3.36e-6, 3.19e-6, 3.01e-6, 2.81e-6, 2.62e-6, 2.21e-6, 1.82e-6, $
    1.45e-6, 1.12e-6, 8.38e-7, 6.13e-7, 4.34e-7, 3.00e-7, 2.01e-7, 1.28e-7, $
    8.04e-8, 4.81e-8, 2.79e-8, 1.56e-8, 2.92e-9, 4.38e-10,5.25e-11,4.51e-12,$
    5.05e-6, 3.48e-6 ]
  v=where(abs(ws-7.0) gt .01) & ws=ws[v] & ts=ts[v]    ; Correction by RJT
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array 10

  ;  Transfer function measurements for GOES-11:
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35798,.35801,2.5889,2.5901]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.869,3.8701]
  ts= [ $
    1.20e-7, 5.95e-7, 1.28e-6, 9.54e-7, 1.72e-6, 2.77e-6, 4.07e-6, 5.59e-6, $
    7.25e-6, 9.01e-6, 1.08e-5, 1.25e-5, 1.40e-5, 1.53e-5, 1.61e-5, 1.69e-5, $
    1.75e-5, 1.77e-5, 1.77e-5, 1.76e-5, 1.71e-5, 1.68e-5, 1.58e-5, 1.53e-5, $
    1.40e-5, 1.04e-5, 1.03e-5, 9.94e-6, 9.67e-6, 9.31e-6, 8.87e-6,          $
    8.34e-6, 7.81e-6, 7.21e-6, 6.65e-6, 5.99e-6, 4.83e-6, 3.74e-6, 2.80e-6, $
    2.03e-6, 1.41e-6, 9.45e-7, 6.09e-7, 1.71e-7, 3.65e-8, 7.32e-10,3.61e-12,$
    1.61e-6, 7.13e-7, 1.35e-5, 1.05e-5]
  tl= [1.96e-8, 1.40e-7, $
    4.21e-7, 9.08e-7, 1.54e-6, 2.34e-6, 3.22e-6, 4.09e-6, 4.88e-6, 5.51e-6, $
    5.95e-6, 6.22e-6, 6.34e-6, 6.36e-6, 6.31e-6, 6.20e-6, 6.07e-6, 5.92e-6, $
    5.75e-6, 4.04e-6, 4.17e-6, 4.26e-6, 4.30e-6, 4.29e-6, 4.24e-6, 4.15e-6, $
    4.03e-6, 3.87e-6, 3.70e-6, 3.50e-6, 3.28e-6, 3.07e-6, 2.62e-6, 2.18e-6, $
    1.75e-6, 1.38e-6, 1.05e-6, 7.80e-7, 5.63e-7, 3.98e-7, 2.72e-7, 1.79e-7, $
    1.15e-7, 7.06e-8, 4.22e-8, 2.44e-8, 5.02e-9, 8.37e-10,1.13e-10,1.11e-11,$
    5.69e-6, 3.92e-6 ]
  v=where(abs(ws-7.0) gt .01) & ws=ws[v] & ts=ts[v]    ; Correction by RJT
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array 11

  ;  Transfer function measurements for GOES-12:
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35799,.35801,2.5889,2.5901]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.8699,3.8701]
  ts = [ $
    1.18e-7, 5.88e-7, 1.26e-6, 9.42e-7, 1.70e-6, 2.73e-6, 4.02e-6, 5.52e-6, $
    7.16e-6, 8.90e-6, 1.07e-5, 1.23e-5, 1.39e-5, 1.51e-5, 1.59e-5, 1.67e-5, $
    1.73e-5, 1.75e-5, 1.75e-5, 1.74e-5, 1.69e-5, 1.66e-5, 1.57e-5, 1.51e-5, $
    1.38e-5, 1.03e-5, 1.02e-5, 9.86e-6, 9.60e-6, 9.25e-6, 8.82e-6,          $
    8.30e-6, 7.78e-6, 7.19e-6, 6.63e-6, 5.98e-6, 4.83e-6, 3.75e-6, 2.82e-6, $
    2.05e-6, 1.42e-6, 9.58e-7, 6.20e-7, 1.76e-7, 3.80e-8, 7.88e-10,4.06e-12,$
    1.59e-6, 7.04e-7, 1.34e-5, 1.04e-5]
  tl = [ 1.84e-8, 1.32e-7, $
    3.94e-7, 8.51e-7, 1.45e-6, 2.19e-6, 3.01e-6, 3.83e-6, 4.57e-6, 5.16e-6, $
    5.58e-6, 5.83e-6, 5.94e-6, 5.96e-6, 5.91e-6, 5.81e-6, 5.69e-6, 5.54e-6, $
    5.39e-6, 3.78e-6, 3.90e-6, 3.98e-6, 4.02e-6, 4.01e-6, 3.96e-6, 3.88e-6, $
    3.76e-6, 3.62e-6, 3.45e-6, 3.26e-6, 3.06e-6, 2.86e-6, 2.44e-6, 2.03e-6, $
    1.63e-6, 1.28e-6, 9.70e-7, 7.21e-7, 5.19e-7, 3.66e-7, 2.50e-7, 1.63e-7, $
    1.05e-7, 6.43e-8, 3.82e-8, 2.20e-8, 4.49e-9, 7.40e-10,9.87e-11,9.58e-12,$
    5.33e-6, 3.67e-6]
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array 12

  ;  Transfer function measurements for GOES-13: originally copy of GOES 14, now correct
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35799,.35801,2.5889,2.5901]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.8699,3.8701]
  ts = [ $
    1.206E-07,5.992E-07,1.286E-06,9.608E-07,1.730E-06,2.784E-06,4.095E-06,5.625E-06, $
    7.302E-06,9.074E-06,1.089E-05,1.258E-05,1.413E-05,1.543E-05,1.619E-05,1.704E-05, $
    1.762E-05,1.783E-05,1.785E-05,1.769E-05,1.723E-05,1.687E-05,1.592E-05,1.535E-05, $
    1.405E-05,1.047E-05,1.034E-05,9.988E-06,9.717E-06,9.353E-06,8.907E-06,8.369E-06, $
    7.837E-06,7.235E-06,6.668E-06,6.004E-06,4.833E-06,3.746E-06,2.803E-06,2.026E-06, $
    1.403E-06,9.408E-07,6.053E-07,1.691E-07,3.594E-08,7.114E-10,3.444E-12, $
    1.616E-06,7.180E-07,1.355E-05,1.055E-05]
  tl = [ $
    1.738E-08,1.246E-07,3.735E-07,8.058E-07,1.370E-06,2.072E-06,2.851E-06,3.627E-06, $
    4.322E-06,4.873E-06,5.264E-06,5.495E-06,5.598E-06,5.601E-06,5.546E-06,5.444E-06, $
    5.317E-06,5.169E-06,5.010E-06,3.502E-06,3.603E-06,3.665E-06,3.683E-06,3.662E-06, $
    3.598E-06,3.503E-06,3.378E-06,3.226E-06,3.056E-06,2.868E-06,2.668E-06,2.477E-06, $
    2.074E-06,1.688E-06,1.323E-06,1.011E-06,7.451E-07,5.364E-07,3.727E-07,2.529E-07, $
    1.657E-07,1.036E-07,6.324E-08,3.684E-08,2.072E-08,1.125E-08,1.931E-09,2.621E-10, $
    2.813E-11,2.123E-12,4.952E-06,3.409E-06]
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array 13

  ;  Transfer function measurements for GOES-14:
  ; no copy of the calibration document: Boeing (new manufacturer) are
  ; protecting any potential competitive advantage. Data from tables
  ; suppled by Rodney Viereck
  ; wavelength values are the same, just need to re-order tables
  ; to move .358, 2.59 pairs to end of ws, 3.87 pair to end of wl
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35799,.35801,2.5889,2.5901]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.8699,3.8701]
  ts = [ $
    1.167e-07,5.798e-07,1.244e-06,9.296e-07,1.674e-06,2.694e-06,3.963e-06,5.443e-06, $
    7.065e-06,8.780e-06,1.053e-05,1.217e-05,1.367e-05,1.493e-05,1.566e-05,1.649e-05, $
    1.705e-05,1.725e-05,1.727e-05,1.711e-05,1.667e-05,1.632e-05,1.540e-05,1.485e-05, $
    1.359e-05,1.012e-05,1.000e-05,9.660e-06,9.398e-06,9.045e-06,8.613e-06, $
    8.092e-06,7.578e-06,6.995e-06,6.446e-06,5.804e-06,4.671e-06,3.619e-06,2.708e-06, $
    1.957e-06,1.355e-06,9.081e-07,5.841e-07,1.630e-07,3.461e-08,6.831e-10,3.294e-12, $
    1.564e-06,6.948e-07,1.310e-05,1.020e-05 ]
  tl = [ 1.864e-08,1.336e-07, $
    4.004e-07,8.640e-07,1.469e-06,2.223e-06,3.059e-06,3.894e-06,4.643e-06,5.238e-06, $
    5.664e-06,5.918e-06,6.038e-06,6.051e-06,6.002e-06,5.903e-06,5.779e-06,5.633e-06, $
    5.476e-06,3.841e-06,3.966e-06,4.050e-06,4.088e-06,4.086e-06,4.036e-06,3.952e-06, $
    3.836e-06,3.689e-06,3.520e-06,3.330e-06,3.124e-06,2.925e-06,2.498e-06,2.078e-06, $
    1.671e-06,1.314e-06,9.998e-07,7.448e-07,5.376e-07,3.799e-07,2.601e-07,1.708e-07, $
    1.098e-07,6.766e-08,4.040e-08,2.338e-08,4.824e-09,8.066e-10,1.093e-10,1.080e-11, $
    5.419e-06,3.730e-06 ]
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array 14

  ; Transfer function measurements for GOES-15:
  ; data suppled by Rodney Viereck 2013 Feb
  ; wavelength values are the same, just need to re-order tables
  ; to move .358, 2.59 pairs to end of ws, 3.87 pair to end of wl
  ws=[.1+.1*findgen(35),3.6+.2*findgen(8),5.5,6,7,8,.35799,.35801,2.5889,2.5901]
  wl=[.2+.2*findgen(32),6.8+.4*findgen(14),13+findgen(4),3.8699,3.8701]
  ts = [ $
    1.171e-07,5.818e-07,1.249e-06,9.328e-07,1.680e-06,2.703e-06,3.976e-06,$
    5.462e-06,7.092e-06,8.815e-06,1.058e-05,1.223e-05,1.374e-05,1.501e-05,$
    1.576e-05,1.660e-05,1.718e-05,1.740e-05,1.744e-05,1.729e-05,1.687e-05,$
    1.654e-05,1.563e-05,1.509e-05,1.384e-05,1.033e-05,1.022e-05,9.902e-06,$
    9.656e-06,9.317e-06,8.897e-06,8.385e-06,7.876e-06,7.296e-06,6.747e-06,$
    6.100e-06,4.951e-06,3.873e-06,2.928e-06,2.140e-06,1.501e-06,1.020e-06,$
    6.665e-07,1.944e-07,4.356e-08,9.851e-10,5.716e-12,1.569e-06,6.971e-07,$
    1.337e-05,1.041e-05]
  tl = [ $
    1.756e-08,1.258e-07,3.772e-07,8.139e-07,1.384e-06,2.094e-06,2.883e-06,$
    3.669e-06,4.376e-06,4.939e-06,5.341e-06,5.583e-06,5.698e-06,5.713e-06,$
    5.670e-06,5.581e-06,5.467e-06,5.334e-06,5.190e-06,3.644e-06,3.767e-06,$
    3.852e-06,3.894e-06,3.898e-06,3.857e-06,3.784e-06,3.680e-06,3.547e-06,$
    3.392e-06,3.217e-06,3.027e-06,2.842e-06,2.442e-06,2.046e-06,1.659e-06,$
    1.316e-06,1.012e-06,7.619e-07,5.566e-07,3.985e-07,2.767e-07,1.845e-07,$
    1.206e-07,7.566e-08,4.606e-08,2.720e-08,5.952e-09,1.063e-09,1.552e-10,$
    1.671e-11,5.138e-06,3.536e-06]
  os=sort(ws) & ol=sort(wl)                            ; Sort data
  ws=ws[os] & wl=wl[ol] & ts=ts[os] & tl=tl[ol]
  wsm[0,ix_nsat]=ws & wlm[0,ix_nsat]=wl & tsm[0,ix_nsat]=ts & tlm[0,ix_nsat]=tl & ix_nsat = ix_nsat + 1 ; Load array 15
  gbshort = gbarshort
  gblonga = gbarlong
  gblongb = gblonga & gblongb[5]=4.43e-6      ; Before & after for GOES-6

;  result = { tsm: tsm, tlm: tlm, wsm: wsm, wlm: wlm, gbshort: gbshort, $
;    gblonga: gblonga, gblongb: gblongb}
    isat = sat - 1
    if anytim(fcheck(goes6date,2e8),/sec) ge 1.416096e8 then gblong=gblonga $
    else gblong=gblongb
    if calibrate then begin
      tsm = tsm / gbshort[isat]
      tlm = tlm / gblong[isat]
    endif
    result = { tsm: tsm[*,isat], tlm: tlm[*,isat], wsm: wsm[*,isat], wlm: wlm[*,isat], gbshort: gbshort[isat], $
    gblong: gblonga[isat], calibrated: calibrate, sat: sat}
    if keyword_set( interpolate ) then result = goes_interpolate_transfer( result, _extra = _extra )
  return, result
end
;--------------------------------------------------------------------------
