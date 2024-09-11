;+
; NAME:
;       PLOT_BSC
; PURPOSE:
;       plot a BSC spectrum
; CALLING SEQUENCE:
;       PLOT_BSC,BSC_INDEX,BSC_DATA
;       PLOT_BSC,BSC_INDEX,BSC_DATA,/NOWIDGET
; INPUTS:
;       BSC_INDEX    - BSC index structures
;       BSC_DATA     - BSC data structure
; KEYWORDS:
;       NOWIDGET     - Don't use the widget environment
; HISTORY:
;       Nov'92  - written by D. Zarro (ARC)
;       Sept'93 - added call to BCS_SPEC_PLOT for single spectrum case
;	30-sep-93, JRL, Check on ss= for call to BCS_SPEC_PLOT
;	15-oct-93, DMZ, Added ebar keyword
;       30-Nov-93, DMZ, added /SECOND keyword to oplot 2nd cmpt
;        9-Dec-93, DMZ, added VUNIT switch
;       13-Dec-93, DMZ, added /BLUE switch 
;        (same effect as /second, and consistent with FIT_BSC and CAL_BSC)
;       24-Jan-94, DMZ, added CLEARPLOT and /PRIMARY keyword
;-

pro plot_bsc,bsc_index,bsc_data,fit_index,fit_data,chan=chan,		$
                Ainfo=Ainfo,over=over,ss=ss, 				$ 
                xrange=xxrange,yrange=yyrange, 				$
                psym=ppsym,linestyle=llinestyle,charsize=ccharsize, 	$
                xoff=xoff_anno,ebar=ebar,       			$
                noobs=noobs,nofit=nofit,notitle=notitle,title=ttitle,   $
                postscript=ps,hc=hc,xsize=xsize,ysize=ysize,primary=primary,$
                nowidget=nowidget,second=second,vunit=vunit,blue=blue

on_error,1

;-- check inputs

ok=bsc_check(bsc_index,bsc_data)
if (not ok) then begin
 chkarg,'plot_bsc'
 return
endif

;-- call BCS_SPEC_PLOT if only one spectrum 
;   (key_word inheritance would be good here)

clearplot

if ((n_elements(bsc_index) eq 1) and (n_elements(bsc_data) eq 1)) or	$
    (n_elements(ss) eq 1) then begin
 bcs_spec_plot,bsc_index,bsc_data, 					$
                Ainfo=Ainfo,over=over,ss=ss, 				$ 
                xrange=xxrange,yrange=yyrange, 				$
                psym=ppsym,linestyle=llinestyle,charsize=ccharsize, 	$
                xoff=xoff_anno,ebar=ebar,				$
		color=ccolor,ocolor=ocolor,vunit=vunit,			$
                noobs=noobs,nofit=nofit,notitle=notitle,title=ttitle,   $
                postscript=ps,hc=hc,xsize=xsize,ysize=ysize,$
                second=keyword_set(second) or keyword_set(blue),primary=primary
 return
endif


;-- check for possible BSA input

sz=size(bsc_data.counts)
if sz(0) eq 1 then message,'BSC_DATA does not contain data'

;-- try using widgets 

if (!d.name eq 'X') and (not keyword_set(nowidget)) then begin
  wbsc,bsc_index,bsc_data,fit_index,fit_data,err_flag=err
  if err eq 0 then return
endif

;-- Assume that we must use tektronix mode (or no widgets) ---------------

;-- plot lightcurve

hard=0					; Don't do hardcopy
chan_select=1				; Select a channel the first time
chan_uniq = fix(gt_bsc_chan(bsc_index,/uniq)) & chan_uniqs = string(chan_uniq,format='(4i4)')
chan = min(chan_uniq)			; Set up a default
repeat begin

 if not hard then begin

  if chan_select then begin
    if n_elements(chan_uniq) eq 1 then chan = chan_uniq else $
    input,' Available chans = '+chan_uniqs+' ==> Enter:',chan,chan,min(chan_uniq),max(chan_uniq)
    sel_bsc,bsc_index,bsc_data,index,data,chan=chan,ss=ss1	; Select out data from chan=chan
    cps=gt_bsc_crate(index)				; Return counts/sec
    mtitle=('CHAN '+strtrim(chan,2)+': '+gt_bsc_chan(chan,/str))(0)
    chan_select = 0
  endif

;-- get nearest spectrum

  if (!d.name eq 'X') and (!d.window gt -1) then wshow
  utplot,index,cps,ytitle='COUNTS PER SEC',xtitle='****',title=mtitle
 
  message,'USE CURSOR TO SELECT TIME OF SPECTRUM',/cont
  cursor,t1,y1,/data					; Click on the desired time
  diff = min(abs(t1-int2secarr(index)),loc)
  outplot,index(loc([0,0])),!y.crange,linestyle=2
  
;-- Set up the annotation label

  plabels=' '
  if (index.bsc.deadtime_ans)(loc) gt 0 then plabels=[plabels,'Deadtime corrected']
  if (index.bsc.curve_ans)(loc)    gt 1 then plabels=[plabels,'Curvature corrected']
 endif 					; not hard

;-- plot spectrum

 bcs_spec_plot,index,data,psym=10,hc=hard,font=hard-1,ss=loc	;plabels=plabels
 hard=0
 if !d.name eq 'X' then wshow
 message,' Spectrum Index = '+strtrim(ss1(loc),2)+'  >> enter: ',/contin
 if n_elements(ss) lt n_elements(bsc_index) then $
 print,'      0 - to change channel'
 print,'      1 - to select another spectrum'
 print,'      2 - to make a hard copy'
 print,'      3 - to quit'

 if (not hard) and (!d.name eq 'X') then wshow
 input,' Enter ',ans,1,0,3
 if ans eq 2 then hard=1
 if ans eq 0 then chan_select = 1

endrep until (ans eq '3')

empty
end
