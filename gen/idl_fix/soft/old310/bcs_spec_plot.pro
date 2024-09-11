pro bcs_spec_plot,Index,Data,Ainfo=Ainfo,over=over,ss=ss,		$
		xrange=xxrange,yrange=yyrange,				$ ; Plot range
		psym=ppsym,linestyle=llinestyle,charsize=ccharsize,	$ ; Style controls
		xoff=xoff_anno,font=font,ytitle=yytitle,		$ ; Style controls
		color=ccolor,ocolor=ocolor,				$ : Style controls
		noobs=noobs,nofit=nofit,notitle=notitle,title=ttitle,	$ ; Control parameters
		postscript=ps,hc=hc,xsize=xsize,ysize=ysize,ebar=ebar,	$
                second=second,vunit=vunit,portrait=portrait,eps=eps,	$
		noatomic=noatomic,nodate=nodate,file=file,noannotate=noannotate,		$
		x0=x0off,y0=y0off,xpage=xpage1,ypage=ypage1,primary=primary, $
		nouncert=nouncert
;+
; NAME:
;  bsc_spec_plot
; PURPOSE:
;  Plot BCS observed or synthetic spectra 
; CALLING SEQUENCE:
;  bcs_spec_plot,bsc_index,bsc_data		; Defaults to the first plot
;  bcs_spec_plot,bsc_index,bsc_data,ss=10		; Plot spectrum 10
; INPUTS:
;  INDEX  = BSC Index structure or wavelength vector
;  DATA   = BSC Data structure  or data array
; OPTIONAL INPUT KEYWORDS:
;  AINFO   = Optional information structure
;  over	  = If set, over plot on an existing plot
;  ss	  = Scalar value which specifies the index of bsc_index,bsc_data to plot.
;  xoff	  = Number between 0 and 1 which specifies where the plot annotation goes
;	    (this is useful in case the user wants to specify a different size window).
;  font	  = Specifies the font to use (make this a number -- not a string)
;	    0=Use hardware fonts.  -1=The current default fonts
;  nobos  = If set, don't plot the data (by default plots data and overplots the fit)
;  nofit  = If set, don't plot the fit  (by default plots data and overplots the fit)
;  notitle= If set, don't do print title
;  title  = User specified title (default title will put the time on the plot)
;  color  = color keyword for PLOT
;  ocolor = color keyword for OPLOT
;  xrange,yrange,psym,linestyle,charsize ==> Normal keywords for plot
;  ebar   = overplot error bars [can come in as 0/1 or a vector of errors]
;  second = overplot secondary cmpt (if present)
;  primary = overplot primary cmpt (if present)
;  vunit  = print Td6 in km/s units
;  noannotate = do not print annotation
; PostScript Specific:
;  hc	  = If set, make a hardcopy version.
;  PostScript  = If set, send the output to an idl.ps file 
;		 (but don't close or send to printer)
;  eps	  = If set, generate encapsulated PostScript file (closed, not sent to printer)
;	         (if /Post,/eps is specified, don't close the file)
;  xsize  = Specifies the PostScript X-axis length (inches)
;  ysize  = Specifies the PostScript Y-axis length (inches)
;  xpage  = Specifies the PostScript X page size (inches)
;  ypage  = Specifies the PostScript Y page size (inches)
;  x0,y0  = Specifies the PostScript X and Y-axis origins (inches)
;  portrait= if set, do the plot in portrait mode.  (Recommend /portrait,/noatomic be used)
;  file	  = Specify the output plot file name (default = idl.ps)
;  noatomic= if set, don't put the atomic code labels on the PS plot (near X-axis labels)
;  nodate  = if set, don't put the date on the PS plot
;  nouncert= If set, don't put +/- uncertainties on the plot
;  
; OPTIONAL OUTPUT KEYWORDS:
;  
; MODIFICATION HISTORY:
;  30-sep-93, J. R. Lemen (LPARL), Written
;   7-oct-93, DMZ and JRL -- Added color and ocolor keywords
;  18-Oct-93, DMZ and JRL -- added ebar keyword
;  18-Oct-93, DMZ -- allowed for vector and/or scalar inputs for EBAR
;  30-Nov-93, DMZ -- added oplot of secondary cmpt (via /SECOND switch)
;   9-Dec-93, DMZ -- added VUNIT keyword
;  20-Dec-93, DMZ -- fixed small bug in second cmpt plotting and annotation
;  29-dec-93, JRL -- Added /portrait,/noatomic,/eps,x0off,y0off,xpage,ypage
;   7-jan-94, JRL -- Added an "empty" to flush PS buffer (needed sometimes for /eps)
;  23-Jan-94, DMZ -- added /PRIMARY, /NOANNOTATE keywords 
;                    + more error checking and general cleanup
;   9-Apr-94, DMZ -- fixed bug with /PRIM
;  21-Jun-94, DMZ -- further propagated VUNIT
;  30-jun-94, JRL -- Added the /NOUNCERT keyword
;-
on_error,2			; Return to caller

 if n_params() lt 2 then message,'Calling sequence ==> BCS_SPEC_PLOT,BCS_INDEX,BCS_DATA'
 if n_elements(ss) eq 0 then ss = 0


xstyle=0 & ystyle=0
if n_elements(ccharsize) eq 0 then charsize = 1.3   else charsize = ccharsize
if n_elements(xxrange)   eq 0 then xrange = [0.,0.] else begin
	xrange = xxrange & xstyle=1
endelse
if n_elements(yyrange)   eq 0 then yrange = [0.,0.] else begin 
	yrange = yyrange & ystyle=1
endelse
if n_elements(llinestyle) gt 0 then linestyle=llinestyle else linestyle=0

xtitle = 'WAVELENGTH (Ang)'
ytitle = 'FLUX (Photon cm!U-2!N  s!U-1!N  A!U-1!N)'
title  = ' '		; Initialize to null
if n_elements(file) eq 0 then file = 'idl.ps'	; Setup filename

; Did the data come in as arrays or structures?

qfit = 0		; Fit data is not present or not requested
qobs = 0		; Observed data is not present or not requested

if datatype(index,2) eq 8 then begin
  Tags = tag_names(data(ss))
  if keyword_set(noobs) then qobs = 0 else begin
     jj = where(tags eq 'FLUX',count1)		; Look for flux calibrated first
     if (count1 gt 0) then qobs = 1 else begin
       jj = where(tags eq 'COUNTS',count1)
       if count1 gt 0 then qobs = 1
     endelse
  endelse
  jj = where(tags eq 'FLUX_FIT',count2)
  if (count2 gt 0) then qfit = 1

  if qobs+qfit eq 0 then begin
     message,'No data to plot '		; Return -- no data requested
  endif else begin
     if qobs then begin

       sel_bsc,index(ss),data(ss),tindex,tdata,wave,flux,eflux,$
               counts=counts,error=error
       fluxcal = (tindex.bsc.physunits_ans gt 1)
       wavecal = (tindex.bsc.wavedisp_ans  gt 1)
       XX=wave
       
       if fluxcal then begin
	  YY = flux
          EE = eflux
       endif else begin
	  accum = tindex.bsc.actim/1000.
	  YY = counts/accum
          EE = error/accum
	  ytitle = 'INTENSITY (COUNTS PER SEC PER BIN)'
       endelse

	; Get the non-zero wavelength bins

       jj = where(XX gt 0,count)
       if count eq 0 then begin
        message,'zero data to plot',/cont
        return
       endif              
       XX = XX(jj) & YY = YY(jj) & EE=EE(jj)

       xx = (xx(1:*) + xx) / 2.		; Make it the central wavelength
       jj = where(Tags eq 'FLUX_FIT',count2)
       if count2 gt 0 then xx = xx + index(ss).fit.wshift
       if n_elements(ppsym) eq 0 then ppsym = 10
     endif

;-- Get the fit data (skip blank fields since sometimes FIT_BSC will
;   add a FLUX_FIT field, but not insert a fitted spectrum. 
;   This happens when FIT_BSC fails to converge)

     if qfit then begin
      sel_bsc,index(ss),data(ss),tindex,tdata,fwave=xx2,fit=yy2
      jj = where(XX2 gt 0,count)
      if count gt 0 then begin
       XX2 = XX2(jj) & YY2 = YY2(jj)	; Get the non-zero wavelength bins
       if n_elements(ppsym) eq 0 then ppsym = 0
       if not qobs then begin
        XX = XX2 & YY = YY2 
        delvarx,xx2,yy2
       endif 
      endif else begin
       delvarx,xx2,yy2
       qfit=0
      endelse
     endif

     if keyword_set(over) then delvarx,xx2,yy2	; Only plot one component

;  If plotting two vectors --- set up the plotting range

     if (n_elements(XX) gt 0) and (n_elements(XX2) gt 0) then begin
	 if n_elements(xxrange) eq 0 then xrange = [min([xx,xx2]),max([xx,xx2])]
         if n_elements(yyrange) eq 0 then yrange = [min([yy,yy2]),max([yy,yy2])]
     endif

;  Set up the title:
	title = (get_bsc_anno(index(ss),vunit=vunit))(0)
  endelse     
endif else begin			; Data came is as arrays
     XX = index
     YY = data(*,ss)
     if (size(ebar))(0) eq 1 then ee=ebar else ee=0
     if n_elements(ppsym) eq 0 then ppsym = 0
     if n_elements(Ainfo) ne 0 then title = get_bsc_anno(Ainfo,vunit=vunit)
endelse


; -------------  Set up for plotting ---------------------

save_dname = !d.name
if save_dname eq 'PS' then save_dname = 'X'

if keyword_set(ps) or keyword_set(hc) or keyword_set(eps) then qPost = 1 else qPost = 0
if qPost then begin

; xlen and ylen are the actual plot axis lengths:

  if not keyword_set(portrait) then begin
; Set up the plot page size for landscape mode
     XPAGE = 10.6 & YPAGE = 8.5		; U.S. page size
     if n_elements(xpage1) ne 0 then xpage = xpage1
     if n_elements(ypage1) ne 0 then ypage = ypage1
     XOFFS = 0.   & YOFFS = XPAGE
     if n_elements(xsize) eq 0 then xlen = 7. else xlen = xsize
     if n_elements(ysize) eq 0 then ylen = 5. else ylen = ysize
  endif else begin
; Set up the plot page size for portrait mode
     XPAGE = 8.5 & YPAGE = 10.6		; U.S. page size
     if n_elements(xpage1) ne 0 then xpage = xpage1
     if n_elements(ypage1) ne 0 then ypage = ypage1
     XOFFS = 0.   & YOFFS = 0.
     if n_elements(xsize) eq 0 then xlen = 5. else xlen = xsize
     if n_elements(ysize) eq 0 then ylen = 3.6 else ylen = ysize
  endelse

; X0,Y0 are the coordinates of the lower left corner of the plot window
; relative to the lower left corner of the page.
     X0=(XPAGE-XLEN)/2 & Y0=(YPAGE-YLEN)/2	; Inches
     if n_elements(X0off) ne 0 then Xoffs = X0off	; User supplied offset
     if n_elements(Y0off) ne 0 then Yoffs = Y0off	; User supplied offset

  if not keyword_set(over) then begin
     if !d.name ne 'PS' then set_plot,'ps'
     if keyword_set(portrait) then			 		$
	device,/portrait, encap=keyword_set(eps),filename=file else 	$
	device,/landscape,encap=keyword_set(eps),filename=file
     device,/inches,xsize=xpage,ysize=ypage,xoffs=xoffs,yoffs=yoffs
     !p.position = [X0/XPAGE,Y0/YPAGE,(X0+XLEN)/XPAGE,(Y0+YLEN)/YPAGE]
;     !p.ticklen = 4.5e-3*(XLEN>YLEN)		; Scott Claflin's Recommendation
  endif
endif
    
if n_elements(ttitle)  gt 0 then title = ttitle 	; Yes? - Use supplied mtitle
if n_elements(yytitle) gt 0 then ytitle = yytitle	; Yes? - Use supplied ytitle
if keyword_set(notitle) then title=' '			; Yes? - No mtitle

;---  Set up the color for the plots ---
if !d.name eq 'PS' then begin
   color = 0 & ocolor = 0 & ffont = 0			; Default to Hardware font for PS
endif else begin
  if n_elements(ccolor) eq 0 then color = !d.n_colors-1 else color = ccolor
  if n_elements(ocolor) eq 0 then ocolor= !d.n_colors-1
  ffont = -1						; Default to vector drawn fonts
endelse

if n_elements(font) ne 0 then 	$
  if font ge 3 then begin
     title = '!'+strtrim(font,2)+title 
     ffont = -1
  endif else if font ne -1 then ffont = 0		; Set the hardware font option


if not keyword_set(over) then 							$
		plot,xx,yy,xtitle=xtitle,ytitle=ytitle,psym=ppsym,		$
		   charsize=charsize,xrange=xrange,yrange=yrange,title=title,	$
		   linestyle=linestyle,font=ffont,color=color else		$
		oplot,xx,yy,psym=ppsym,linestyle=linestyle,color=ocolor

;-- oplot fitted primary and secondary components

if qfit then begin

 ncomp=index(ss).fit.ncomp_fit
 sel_bsc,index(ss),data(ss),fwave=xx2,fit=yy2,sfit=yy3
 ok=where(xx2 gt 0,count)

 if (count gt 0) and (ncomp gt 0) then begin

  if (not keyword_set(nofit)) then $
  oplot,xx2(ok),yy2(ok),linestyle=linestyle,color=ocolor  ;-- plot total

  if ncomp eq 2 then begin

   if (keyword_set(primary)) then $   ;-- plot primary
    oplot,xx2(ok),yy2(ok)-yy3(ok),psym=0,linestyle=linestyle+1,color=ocolor

   if keyword_set(second) then $      ;-- plot secondary
    oplot,xx2(ok),yy3(ok),psym=0,linestyle=linestyle,color=ocolor
   
  endif 
 endif else ncomp=1
endif

;-- oplot uncertainties

if n_elements(ebar) eq 0 then ebar=0
if (min(ebar) ne 0) or (min(ebar) ne max(ebar)) then begin
 if n_elements(ee) gt 1 then eplot,xx,yy,ey=ee,/noclip
endif
                
  
; Set up the X position of the fitting parameter annotation:
if keyword_set(nouncert) then xoff_corr = 0. else xoff_corr = 0.65	; Shift correction for atomic label
if n_elements(xoff_anno) ne 0 then x1 = xoff_anno else $
     if keyword_set(nouncert) then begin
	if qPost then x1 = (x0 + Xlen - 2.) / xpage else x1 = .75 
     endif else begin
	if qPost then x1 = (x0 + Xlen - 2. - xoff_corr) / xpage else x1 = .68
     endelse
xx1 = x1 
if qPost then xx1 = ( xx1 * xpage + xoff_corr ) /xpage		; Position of atomic labels

; Add on the fitting parameters

if qfit and not keyword_set(noannotate) then begin	
 uncert = ([2,0])(keyword_set(nouncert))	; If error bars on plot, use uncert=2 (gives + over -)
 anno1 = get_bsc_anno(index(ss),vunit=vunit,uncert=uncert)	; Get the plot annotation string vector

 if n_elements(anno1) gt 1 then begin
  char_anno = charsize * 1.		; Reduce the character size by 0%

  y1 = .85  & if qPost then y1 = (y0 + .90 * ylen) / ypage
  dy = .03  & if qPost then dy = .025 * 8.5/ypage * charsize/1.3

  j0 = 1 
  for j=j0,j0+2 do begin
   xyouts,x1,y1,anno1(j),charsize=char_anno,/norm & y1=y1-dy 
  endfor

; -- Print the 2nd Component Labels

  if ncomp eq 2 then begin
    y1 = y1 - dy / 2.				; Add some space
    j0 = j
    for j=j0,j0+4 do begin 
     xyouts,x1,y1,anno1(j),charsize=char_anno,/norm & y1=y1-dy 
    endfor
    y1 = y1 - dy / 2.				; Add some space
  endif 

; --  Add the Shift, Chi2/n, Fit_L Labels --
  j0 = j 
  for j=j0,n_elements(anno1)-1 do begin 
   xyouts,x1,y1,anno1(j),charsize=char_anno,/norm & y1=y1-dy 
  endfor
 endif
endif				; qfit and not keyword_set(notitle) 
  

; Add the Time/date on PS Plot -- if this is not an overplot

if (!d.name eq 'PS') and not keyword_set(notitle) and not keyword_set(over) then begin	
  y1 = (y0 - .10 * ylen) / ypage & dy = .015
  if not keyword_set(nodate) then 	$
	xyouts,(x0-.5)/xpage,y1-3*(.015),'Plot done: '+fmt_tim(!stime),charsize=.90,/norm

; Add additional Atomic Code info on PS Plot

  if not keyword_set(noatomic) then begin
    if qfit then ttt = get_bsc_anno(index(ss),/atomic,vunit=vunit) else $	; Get the Titles
    if n_elements(Ainfo) gt 0 then ttt = get_bsc_anno(Ainfo,vunit=vunit,/atomic)
    if n_elements(ttt) ne 0 then begin
      nt = n_elements(ttt) < 4			; Only print the first 4 lines
      for i=0,n_elements(ttt)-1 do begin
        xyouts,xx1,y1,ttt(i),charsize=1.0,/norm & y1=y1-dy
      endfor
    endif
  endif						; not keyword_set(noatomic)
endif

empty						; Flush the buffer
if keyword_set(hc) then pprint, file		; Send the plot to the printer
if not keyword_set(ps) then begin
  set_plot,save_dname
  clearplot			; Reset the defaults
endif 

end
