;+
; NAME:
;       PLOTSPEC
; PURPOSE:
;      plot spectra
; CALLING SEQUENCE:
;      plotspec,x,y
; INPUTS:
;      x = wavelength array
;      y = data array
; KEYWORDS:
;      /hard : to hard copy spectrum
;      /bin  : value by which to bin spectrum (e.g. bin=2 will double bin data)
;      /over : to overplot successive spectra
;      /avg  : to average successive spectra
;       gang : value by which to gang plots (e.g. 2 gives 2x2; [2,3] gives 2x3)
;      plabels : plot information labels
;      /draw : alerts PLOTSPEC that window may be a DRAW widget
;      /logx : Log x-axis
;      /logy : Log y-axis
;      linestyle,psym : obvious
;      xtitle,ytitle : obvious
; MODIFICATION HISTORY:     
;      DMZ (ARC) Jan'92
;-

pro plotspec,x,y,hard=hard,bin=bin,over=over,avg=avg,plabels=plabels,$
             xtitle=xtitle,ytitle=ytitle,gang=gang,xrange=xrange,$
             yrange=yrange,psym=psym,mtitle=mtitle,draw=draw,logx=logx,$
             logy=logy,linestyle=linestyle,font=font,ebar=ebar,title=title

common wind,wval
common last_spec,last_x,last_y,last_linestyle,last_psym,last_plabels,$
                 last_xrange,last_yrange,last_xstyle,last_ystyle


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

suff='' & xstyle=0 & ystyle=0
if datatype(plabels) ne 'STR' then plabels=''
if keyword_set(over) then over=1 else over=0
if keyword_set(logx) then logx=1 else logx=0
if keyword_set(logy) then logy=1 else logy=0
if (n_elements(xrange) lt 2) then xrange=[0.,0]
if (xrange(0)*xrange(1) ne 0) and (xrange(1) ne xrange(0)) then xstyle=1

;
;then xrange=[min(x),max(x)] else $
; xstyle=1

if (n_elements(yrange) lt 2) then yrange=[0.,0]
if (yrange(0)*yrange(1) ne 0) and (yrange(1) ne yrange(0)) then ystyle=1

; begin
; irange=where( (x le max(xrange)) and (x ge min(xrange)),count)
; if count eq 0 then yrange=[min(y),max(y)] else $
;  yrange=[min(y(irange)),max(y(irange))] 
;endif else ystyle=1


xrange=[min(xrange),max(xrange)]
yrange=[min(yrange),max(yrange)]

if (n_elements(xtitle) eq 0) then xtitle=''
if (n_elements(ytitle) eq 0) then ytitle=''
if (n_elements(mtitle) eq 0) then mtitle=''
if (n_elements(title) ne 0) then mtitle=title
if n_elements(linestyle) eq 0 then linestyle=0
if n_elements(psym) eq 0 then psym=10
if n_elements(font) eq 0 then font=-1
if logx then suff='_oi'
if logy then suff='-io'
if logx and logy then suff='_oo'
if keyword_set(hard) then hard=1 else hard=0

if hard then begin
 eflag=test_open(/write)
 if not eflag then return
endif

;-- open an X-Window?

if (!d.name eq 'X') and (not keyword_set(draw)) and (not over) then begin
 if n_elements(wval) eq 0 then wval=!d.window                
 if (!d.window gt 31) or (!d.window lt 0) then begin
  window,retain=2,xsize=640,ysize=640,xpos=1024-640,ypos=864-640,/free
  wval=!d.window
 endif
endif

if (min(y) eq max(y)) and (max(y) eq 0) then begin
 erase & plabels=['ZERO DATA'] & return
endif

if not over then begin 
 last_x=x & last_y=y & last_linestyle=linestyle & last_psym=psym
 last_plabels=plabels & last_xrange=xrange & last_yrange=yrange
 last_xstyle=xstyle & last_ystyle=ystyle
endif

;-- if overlay then replot latest spectrum saved in memory

if hard and over and (n_elements(last_x) ne 0) then hardon=1 else hardon=0

if hardon then begin         ;-- plot previous spectrum first
 tx=x & ty=y & x=last_x & y=last_y 
 tpsym=psym & psym=last_psym
 tstyle=linestyle & linestyle=last_linestyle 
 xrange=last_xrange & yrange=last_yrange
 xstyle=last_xstyle & ystyle=last_ystyle
 over=0
endif

;-- hard copy?

if hard then begin  
 orig_dev=!d.name & set_plot,'PS',/copy
 device,/land,xsize=18,ysize=18,yoff=26.,bits_per_pixel=8
 orig_font=font & font=0
endif

over:

xb=x & yb=y
if keyword_set(ebar) then eb=ebar

;-- rebin data?

if (n_elements(bin) ne 0) and (not over) then begin
 if bin gt 1 then begin
  bin=fix(bin) & xb=binup(x,-bin) & yb=binup(y,-bin) 
  if keyword_set(ebar) then eb=sqrt(binup(ebar^2,-bin)/bin)
 endif
endif


if n_elements(gang) eq 0 then gover=0 else gover=1
if not gover then !p.multi=0

;-- gang plots?

case n_elements(gang) of
  0 : begin !p.multi=0 & gang=[0,0] & end
  1 : begin
       if gang eq 0 then !p.multi=0 else !p.multi([1,2])=gang
      end
 else:!p.multi([1,2])=gang(0:1) 
endcase

;-- plot spectra

if (!d.name eq 'X') and (not keyword_set(draw)) then wshow,wval,1

if (not over) then begin
 call_procedure,'plot'+suff,xb,yb,psym=psym,xtitle=xtitle,ytitle=ytitle,$
  title=mtitle,xstyle=xstyle,ystyle=ystyle,$
  font=font,xrange=xrange,yrange=yrange,linestyle=linestyle
endif else begin
 oplot,xb,yb,psym=psym,linestyle=linestyle
endelse

;-- errors

if keyword_set(ebar) and (not over) then eplot,xb,yb,ey=eb  

;-- loop back for overlay

if hardon then begin 
 x=tx & y=ty & linestyle=tstyle & psym=tpsym & hardon=0 & over=1 & goto,over 
endif            

;-- Postscript labels

if hard then begin

 message,'making hardcopy',/info
 if over then tlabels=[last_plabels,plabels] else tlabels=plabels
 nlab=n_elements(tlabels) & maxy=.9 & miny=.1
 if nlab gt 0 then begin
  if nlab eq 1 then b=0 else b=(miny-maxy)/(nlab-1) 
  for i=0,nlab-1 do xyouts,1.,maxy+b*i,tlabels(i),font=0,/normal
 endif
 device,/close
 lzplot
 set_plot,orig_dev & font=orig_font
endif

return & end

