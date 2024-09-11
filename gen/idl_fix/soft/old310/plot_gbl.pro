pro plot_gbl, sttim, entim, event=event, yrange=yrange
;
;+
;NAME:
;	plot_gbl
;PURPOSE:
;	To plot the GRO/BATSE light curve data
;SAMPLE CALLING SEQUENCE:
;	plot_gbl, '8-may-91 13:00', '8-may-91 13:15'
;	plot_gbl, event=1000
;INPUT:
;	sttim	- The start time to plot
;	entim	- The end time to plot
;OPTIONAL KEYWORD INPUT:
;	event	- If set, plot the light curve for that event
;	yrange	- The Y plotting range
;HISTORY:
;	Written 16-Apr-93 by M.Morrison
;	 6-May-93 (MDM) - Added YRANGE
;-
;
if (keyword_set(event)) then begin
    rd_gbe, '1-jan-91', !stime, gbe
    ss = where(gbe.event eq event)
    if (ss(0) eq -1) then begin
	print, 'PLOT_GBL: Cannot find that event'
	return
    end else begin
	sttim = anytim2ints(gbe(ss(0)), off=-2*60.)			;back up 2 minutes
	entim = anytim2ints(gbe(ss(0)), off=gbe(ss(0)).duration+2*60.)	;go forward 2 minutes
    end
end

rd_gbl, sttim, entim, gbl, status=status

if (status gt 0) then begin
    print, 'PLOT_GBL: Do data available for that time period'
    return
end

ytit = 'Counts/sec/2000 cm^2'
tit = 'GRO/BATSE DISCLA Rates (1.024 sec averages)'
utplot, gbl, gbl.channel1+gbl.channel2, ytit=ytit, tit=tit, psym=10, xstyle=1, yrange=yrange
;outplot, gbl, gbl.channel2, psym=10
;
end
