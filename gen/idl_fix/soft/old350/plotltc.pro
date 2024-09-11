;+
; NAME:
;	plotltc
; PURPOSE:
;	plot light curve
; CATEGORY:
;       plotting
; CALLING SEQUENCE:
;	plotltc,t,y,utbase,ebar=ebar,/log,/hard,xrange=xrange,yrange=yrange,xtitle=xtitle,$
;       ytitle=ytitle,mtitle=mtitle,plabels=plabels,/draw,/over,interval
; INPUTS:
;       x = time axis
;       y = data array
;       utbase = UTBASE of data (string for SMM UTPLOT, float for YOHKOH)
; KEYWORDS:
;       ebar = data uncertainties 
;       /log = plot lightcurve on logarithmic scale
;       /hard = make a hard copy of each plot
;       /draw = plot window may be a DRAW widget
;       /over = overplot lightcurves
; PROCEDURE:
;	uses UTPLOT
; MODIFICATION HISTORY:
;	Written by DMZ (ARC) Jan'92
;-

pro plotltc,x,y,utbase,ebar=ebar,log=log,hard=hard,xrange=xrange,yrange=yrange,$
         xtitle=xtitle,ytitle=ytitle,mtitle=mtitle,gang=gang,plabels=plabels,$
         draw=draw,over=over,font=font,interval=interval,psym=psym

common wind,wval

err=0
if (n_elements(x) lt 2) or (n_elements(y) lt 2) then err=1
if not err then begin
 if (min(x) eq max(x)) or (min(y) eq max(y)) then err=1
endif

if err then begin
 plabels='NO DATA TO PLOT'
 plot,[0,1] & oplot,[1,0]
 message,plabels,/cont
 return
endif

if n_elements(xtitle) eq 0 then xtitle='UNIVERSAL TIME'
if n_elements(ytitle) eq 0 then ytitle=''
if n_elements(mtitle) eq 0 then mtitle=''
if n_elements(font) eq 0 then font=-1
if (not keyword_set(over)) then over=0 else over=1

;-- hard copy?

if keyword_set(hard) then hard=1 else hard=0

if hard then begin
 eflag=test_open(/write)
 if not eflag then return
endif

if hard then begin 
 orig_dev=!d.name & set_plot,'PS',/copy
 device,/land,xsize=18,ysize=18,yoff=26.,bits_per_pixel=8
 orig_font=font & font=0
endif

;-- open an X-Window?

if (!d.name eq 'X') and (not keyword_set(draw)) and (not over) then begin
 if n_elements(wval) eq 0 then wval=!d.window                
 if (!d.window gt 31) or (!d.window lt 0) then begin
  window,retain=2,xsize=640,ysize=640,xpos=1024-640,ypos=864-640,/free
  wval=!d.window
 endif
endif

;-- gang plots?

case n_elements(gang) of
  0 : begin !p.multi=0 & gang=[0,0] & end
  1 : begin
       if gang eq 0 then !p.multi=0 else !p.multi([1,2])=gang
      end
 else:!p.multi([1,2])=gang(0:1) 
endcase


if keyword_set(log) then ytype=1 else ytype=0

xb=x & yb=y & np=n_elements(x)
diff=xb(1:*)-xb
nok=where(diff lt 0,count)
if count gt 0 then xb(nok(0)+1:*)=xb(nok(0)+1:*)+24*3600.

if keyword_set(interval) then begin
 xb=(transpose(reform([xb,xb+interval],np,2)))(*)
 yb=(transpose(reform([yb,yb],np,2)))(*)
endif

;-- plot ranges

xstyle=0
if (n_elements(xrange) lt 2) then xrange=[0.,0]
if (xrange(0)*xrange(1) eq 0) or (xrange(1) eq xrange(0)) then xrange=[min(xb),max(xb)] else $
 xstyle=1

ystyle=0
if (n_elements(yrange) lt 2) then yrange=[0.,0]
if ((yrange(0) eq 0) and (yrange(1) eq 0)) or (yrange(1) eq yrange(0)) then begin
 irange=where( (x le max(xrange)) and (x ge min(xrange)),count)
 if count eq 0 then yrange=[min(y),max(y)] else $
  yrange=[min(y(irange)),max(y(irange))] 
endif else ystyle=1
if keyword_set(log) then yrange(0)=(yrange(0) > 1)

yrange=[min(yrange),max(yrange)]
xrange=[min(xrange),max(xrange)]

if over then oplot,xb,yb else $
 call_procedure,'utplot',xb,yb,utbase,xtitle=xtitle,ytitle=ytitle,$
  title=mtitle,yrange=yrange,xrange=xrange,xstyle=xstyle,$
   font=font,ystyle=ystyle,ytype=ytype,psym=psym

if (!d.name eq 'X') and (not keyword_set(draw)) then wshow,wval,1

;--errors

if keyword_set(ebar) then begin
 if keyword_set(interval) then begin
  xb=rebin(xb,np) & yb=rebin(yb,np)
 endif
 eplot,xb,yb,ey=ebar
endif

;-- plot labels

if hard then begin
 message,'making hardcopy',/info
 nlab=n_elements(plabels) & maxy=.9 & miny=.1
 if nlab gt 0 then begin
  if nlab eq 1 then b=0 else b=(miny-maxy)/(nlab-1) 
  for i=0,nlab-1 do xyouts,1.,maxy+b*i,plabels(i),font=0,/normal
 endif
 device,/close 
 lzplot
 set_plot,orig_dev 
 font=orig_font
endif

return & end
  
