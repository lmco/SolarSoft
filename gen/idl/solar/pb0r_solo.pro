;+
; Project     : Solar Orbiter
;
; Name        : pb0r_solo
;
; Purpose     : Return p0, b0, l0, and solar radius as viewed from
;               Solar Orbiter.
;
; Category    : imaging, maps
;
; Syntax      : IDL> pbr=pb0r(time,l0=l0,roll_angle=roll_angle)
;
; Inputs      : TIME = UT time to compute 
;
; Outputs     : PBR = [p0,b0,rsun]
;
; Keywords    : L0 = central meridian [deg]
;               ROLL_ANGLE = spacecraft roll [deg]
;               ARCSEC = return radius in arcsecs
;
; History     : Written 1 July 2024 - William Thompson (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-

function pb0r_solo,time,arcsec=arcsec,l0=l0,error=error,$
                     roll_angle=roll_angle

forward_function get_sunspice_lonlat,get_sunspice_roll

error=''
l0=0 & roll_angle=0.
pbr=[0.,0.,16.]
if keyword_set(arcsec) then pbr=[0.,0.,960.]
if ~have_proc('get_sunspice_lonlat') then begin
 error='SOLO orbital position routine - get_sunspice_lonlat - not found'
 message,error,/cont
 return,pbr
endif

proj_time=anytim2tai(time,err=error)
if is_string(error) then begin
 pr_syntax,'pbr=pb0r_solo(time)'
 return,pbr
endif

solo_launch=anytim2tai('2020-02-10T04:56')
if proj_time lt solo_launch then begin
 error='SOLO orbital data unavailable for this input time'
 message,error,/cont
 return,pbr
endif

;-- SOLO values of l0, b0, rsun, and roll for input time

error=''
pos=get_sunspice_lonlat(time, 'solo', system="HEEQ", /degrees,err=error)

if is_string(error) then begin
 message,error,/cont
 return,pbr
endif

b0=pos[2]
l0=pos[1]
rsun=sol_rad(pos[0])
if ~keyword_set(arcsec) then rsun=rsun/60.

;-- compute roll

sroll_corr_a=[.12,0.203826,0.45]
sroll_corr_b=[-1.125, 0.0983413,-0.20]

case 1 of
 keyword_set(cor2): val=2
 keyword_set(cor1): val=1
 else: val=0
endcase

roll_angle = -get_sunspice_roll(time, 'solo', err=error,/degrees)

if is_string(err) then begin
 message,err,/cont
 return,pbr
endif

;-- compute p0

p0 = get_sunspice_roll(time, 'solo', system='HEEQ') - $
     get_sunspice_roll(time, 'solo', system='GEI')

return,[p0,b0,rsun]
end

