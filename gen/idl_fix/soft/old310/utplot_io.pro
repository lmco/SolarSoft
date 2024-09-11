;.........................................................................
;+
; NAME:
;	UTPLOT_IO
; PURPOSE:
;	Plot X vs Y with Universal time labels on bottom X axis.  X axis
;	range can be as small as 5 msec or as large as 99 years. Y-axis is
;	logarithmic.
; CALLING SEQUENCE:
;	UTPLOT_IO,X,Y,UTSTRING,LABELPAR=LBL, /SAV,TICK_UNIT=TICK_UNIT,$
;		MINORS=MINORS, /NOLABEL, /YOHKOH ,$
;		[& ALL KEYWORDS AVAILABLE TO PLOT]
; 
; IDENTICAL TO UTPLOT	
; HISTORY:
;       11-Nov-92 (MDM) - Removed "ztype" keyword call to UTPLOT
;       19-Apr-93 (MDM) - Removed "zmargin" keyword call to UTPLOT
;	 7-jan-94 ras   - added xthick and ythick
;       23-feb-94 JRL   - Fixed xthick and ythick options
;-

PRO UTPLOT_IO, X, Y, UTSTRING, LABELPAR=LBL ,SAVE=SAV,TICK_UNIT=TICK_UNIT,$
	MINORS=MINORS , NOLABEL=NOLABEL, YOHKOH=YOHKOH, timerange=timerange, $
	background=background, channel=channel, charsize=charsize, $
	charthick=charthick, clip=clip, color=color, $
	font=font, linestyle=linestyle, noclip=noclip, nodata=nodata, $
	noerase=noerase, nsum=nsum, polar=polar, $
	position=position, psym=psym, subtitle=subtitle, symsize=symsize, $
	t3d=t3d, thick=thick, ticklen=ticklen, title=title, year=year, $

	xrange=xrange, xcharsize=xcharsize, xmargin=xmargin, xminor=xminor, $
	xstyle=xstyle, xticklen=xticklen, xticks=xticks, $
;	xtitle=xtitle, $
	xtitle=xtitle, xthick=xthick, $					;ras 7-jan-94/jrl 23-feb-94
	
	ycharsize=ycharsize, ymargin=ymargin, yminor=yminor, yrange=yrange, $
	ystyle=ystyle, yticklen=yticklen, ytickname=ytickname, yticks=yticks, $
;	ytickv=ytickv, ytitle=ytitle, $
	ytickv=ytickv, ytitle=ytitle, ythick=ythick, 		$	;ras 7-jan-94/jrl 23-feb-94

	zcharsize=zcharsize, zminor=zminor, zrange=zrange, $
	zstyle=zstyle, zticklen=zticklen, ztickname=ztickname, zticks=zticks, $
	ztickv=ztickv, ztitle=ztitle

UTPLOT, X, Y, UTSTRING, LABELPAR=LBL ,SAVE=SAV,TICK_UNIT=TICK_UNIT,$
	MINORS=MINORS , NOLABEL=NOLABEL, YOHKOH=YOHKOH, timerange=timerange, $
	$	;include all keywords available to PLOT
	background=background, channel=channel, charsize=charsize, $
	charthick=charthick, clip=clip, color=color, $
	font=font, linestyle=linestyle, noclip=noclip, nodata=nodata, $
	noerase=noerase, nsum=nsum, polar=polar, $
	position=position, psym=psym, subtitle=subtitle, symsize=symsize, $
	t3d=t3d, thick=thick, ticklen=ticklen, title=title, year=year, $

	xrange=xrange, xcharsize=xcharsize, xmargin=xmargin, xminor=xminor, $
	xstyle=xstyle, xticklen=xticklen, xticks=xticks, $
	xtitle=xtitle, xthick=xthick, $

	ycharsize=ycharsize, ymargin=ymargin, yminor=yminor, yrange=yrange, $
	ystyle=ystyle, yticklen=yticklen, ytickname=ytickname, yticks=yticks, $
	ytickv=ytickv, ytitle=ytitle, ythick=ythick, /ytype, $

	zcharsize=zcharsize, zminor=zminor, zrange=zrange, $
	zstyle=zstyle, zticklen=zticklen, ztickname=ztickname, zticks=zticks, $
	ztickv=ztickv, ztitle=ztitle
return
end
