;+
; Purpose: Plot the most recent 3 days of GOES Xray flux from the primary satellite in a PNG file.
;   Calls ssw_get_goesdata which uses JSON service to get most recent data.
;   
; Name: goes_plot_recent
; 
; Keyword Arguments:
;   screen - if set, plot to screen. Otherwise plot to PNG file
;   plotfile - if provided, uses that. Otherwise uses 'goes_latest.png'
;   Note: when run from cron job on hesperia to provide plot for RHESSI website, we've already cd'd to correct dir
;    
; Written: Kim Tolbert March 2022
; Modifications:
;   22-Mar-2022, Kim. Added screen keyword for testing. Added vertical lines at day boundaries.
;-
pro goes_plot_latest, screen=screen, plotfile=plotfile

  gdata = ssw_get_goesdata(reltime(days=-3),reltime(/now),/primary,/xray,/gxd)

  screen = keyword_set(screen)

  if ~screen then begin
    thisDevice = !D.NAME
    set_plot,'z'
    TVLCT, rr, gg, bb, /GET
    device2, get_decomposed=z_decomp, get_pixel_depth=z_pixel_depth

    DEVICE2, SET_RESOLUTION=[800,500], $
      decomposed=0, set_pixel_depth=24
  endif

  linecolors
  sat = gdata[0].satellite
  title='GOES ' + trim(sat) + ' Xray Flux (1-minute data)'
  ytitle='Watts m!u-2!n'
  utplot,gdata.time_tag,gdata.lo,/ylog, yra=[1.e-9, 1.e-2], background=255, col=0, /nodata, /xstyle, /ystyle, ytitle=ytitle, title=title
  outplot,gdata.time_tag,gdata.lo, col=2
  outplot, gdata.time_tag,gdata.hi,col=10
  ssw_legend, ['1.0 to 8.0 A', '.5 to 4. A'],colors=[2,10], textcolor=0, linestyle=0
  
  ; Put GOES class on right y axis
  ylims = crange('y')
  ytickv = 10.^[-13+indgen(12)]
  ytickname = [' ',' ',' ',' ',' ','A','B','C','M','X',' ',' ']
  ymm = ylims + ylims*[-1.e-7, 1.e-7]
  q = where(( ytickv ge ymm(0)) and ( ytickv le ymm(1)), kq)
  if kq gt 0 then axis, yaxis=1, ytickv = ytickv(q),/ylog,  $
    ytickname=ytickname(q),yrange=ylims, yticks=n_elements(q), ticklen=1., color=0
    
  ; Draw vertical lines at day boundaries    
  tlims = minmax(anytim(gdata.time_tag))
  tline = anytim(tlims[0],/date_only)
  while tline lt tlims[1] do begin outplot,anytim(tline+[0.,0.],/vms), ylims, color=0 & tline=tline + 86400. & endwhile

  timestamp, /bottom, charsize=.8, color=0

  ; could have done the following, but don't have as much control
  ;!p.color = 0   &   plot_goes, gdata,dummy, background=255, gcolor=bytarr(6),color=[2,10]

  if ~screen then begin
    image = tvrd(true=1)
    if ~keyword_set(plotfile) then plotfile='goes_latest.png'
    write_png, plotfile, image, rr, gg, bb

    device2, decomp=z_decomp, set_pixel_depth=z_pixel_depth
    set_plot, thisdevice
  endif

end
