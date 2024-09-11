pro get_utevent, starttime, stoptime, estarts, estops, 	 $
	goes=goes, above=above, 			 $ ; goes events
	ksc=ksc, madrid=madrid,				 $ ; contacts
	canberra=canberra, goldstone=goldstone,		 $ ; contacts
	days=days, nights=nights, saas=saas,   		 $ ; ephemeris
	flaremode=flaremode, init=init, 		 $ ; yohkoh events
        sxtf=sxtf, sxtp=sxtp, bcs=bcs, wbs=wbs, hxt=hxt, $ ; observing log
	window=window,					 $ ; +/- time to check
        utrange=utrange,				 $ ; return UT plot range
	info=info, qdebug=qdebug, nevents=nevents,       $ ; text info
	title=tile, $	; old version (pre keyword  inherit)		      
        _extra=_extra   				   ; pass to utplot

;+
;   Name: get_utevent
;  
;   Purpose: return time ranges for various Yohkoh events - optionally use
;   	     the current utplot range for start and stop
;             (from fem, gev, evn, or observing log depending on keyword set)
;
;   Input Parameters:
;      starttime, stoptim - [Optional] Time range to search for events
;
;   Keyword Parameters:
;      goes  - if set, all goes events
;      above - if set, goes events above this level
;      ksc,canberra,goldstone,madrid - if set, return contact info (only one)
;      flaremode - if set, occurences of Yohkoh flare mode
;      
;      info - (output) - optional text descriptor
;      window - if set, search +/- this many hours
;      utrange - if set, return current UTPLOT start and stop in p1/p2
;
;   Calling Sequence:
;      get_utevent, t0, t1, eventstart, eventstop, $
;		[,/ksc, /goes, /day, /night, /saa, /flaremode, info=info]

;      get_utevent, eventstart, eventstop, $
;		[,/ksc, /goes, /day, /night, /saa, /flaremode, info=info]
; 
;      This second form will use current UTPLOT range.
;
;   Calling Examples:
;      get_utevent, strs, stps, /ksc	   ; ksc times in current UTPLOT range
;      get_utevent, strs, stps, /saa 	   ; saa times ""       ""   ""
;      get_utevent, strs, stps, /flare	   ; yohkoh flare modes ""   ""
;      get_utevent, strs, stps, /goes	   ; all goes events
;      get_utevent, strs, stps, goes='c'	   ; times for goes events >= C level
;      get_utevent, t0, t1, /utrange	   ; return current UTPLOT range -> t0/t1
;      get_utevent, ffi, /sxtf		   ; FFI times (from observing log)
;
;   Can be used in conjunction with evt_grid to annotate current utplot
;      utplot....			   ; some utplot
;      get_utevent, strs, stps, /ksc	   ; get times for KSC
;      evt_grid, [strs,stps]		   ; overlay KSC times on current UTPlot
;  
;   History:
;      22-Sep-1994 (SLF) - evt_grid / utplot annotation assistance
;      23-Sep-1994 (SLF) - added DAYS, NIGHTS, SAAS keywords
;      26-Sep-1994 (SLF) - change name from get_event to get_utevent
;			   (avoid name conflict)
;       3-Jan-1995 (SLF) - add observing log keywords (SXTF,SXTP,BCS,HXT,WBS)
;      12-Jan-1995 (SLF) - add /quiet to rd_obs calls
;       9-apr-1995 (SLF) - support old IDL (pre keyword inherit)
;  
;   Common Blocks:
;      get_utevent_blk1, get_utevent_blk2 - avoid repeated calls for same
;                                           dbase/time combinations
;-
; common block to avoid re-reads on succesive calls
common get_utevent_blk1, strt0, stop0, feml, gevl, evnl
common get_utevent_blk2, obsl
;
; --------- define keywords ---------------
goes=keyword_set(goes)
above=keyword_set(above)
nights=keyword_set(nights)
days=keyword_set(days)
saas=keyword_set(saas)
flaremode=keyword_set(flaremode)
obslog=keyword_set(sxtp) or keyword_set(sxtf) or keyword_set(bcs) or $
      keyword_set(hxt)  or keyword_set(wbs)
contacts=keyword_set(ksc) or keyword_set(canberra) or keyword_set(madrid) $
	or keyword_set(goldstone)
utrange=keyword_set(utrange)
init=keyword_set(init)
; --------------------------------------------
case 1 of
   goes or above:              		prefix='gev'
   flaremode:                  		prefix='evn'
   contacts or nights or saas or days:  prefix='fem'   
   obslog: prefix='obs'
   utrange:
   init:
   else: begin
      message,/info,"Need to specify one keyword: " 
      message,/info,"/goes, /above, /ksc, /dsn, /night, /day, /saa, /flaremode
      message,/info,"   /sxtp, /sxpf, /bcs, /hxt, /wbs"
      return
   endcase
endcase

; define starttime and stopptime if not defined
case 1 of 
   n_params() le 2: begin	; try to use utplot values
      if keyword_set(init) then begin

      endif else begin      
         getut, xstart=xstart
         if xstart eq 0 then begin
            tbeep
            message,/info,"You must supply start and stop times or run UTPLOT..."
            return
         endif
         starttime=anytim(xstart+!x.crange(0),out_style='yohkoh')
         stoptime =anytim(xstart+!x.crange(1),out_style='yohkoh')
         if keyword_set(utrange) then begin
            message,/info,"Returning current UTPLOT time range
            
            return
         endif
      endelse
   endcase
   else:   ; start time / stop time passed in
endcase

newstrt=starttime
newstop=stoptime

if keyword_set(init) then begin
   if !d.y_size ne 256 or !d.x_size ne 1024 then  wdef,zz,1024,256,/ur
   utplot,[starttime,stoptime],[100,100],/nodata,yticklen=.001, ytickname= $
      string(replicate(32b,6)), title=title ;_extra = _extra
   return
endif

if n_elements(strt0) eq 0 then begin
   strt0=newstrt
   stop0=newstop
   newtimes=1
endif else newtimes=newstrt ne strt0 or newstop ne stop0

exe=execute('newdata=n_elements(' + prefix + 'l) eq 0')

readnew = newtimes or newdata
estarts=0
estops=0

if obslog then begin		; setup and call rd_obs
   case 1 of
      keyword_set(sxtf): rd_obs,newstrt, newstop,a,data,/nobcs,/quiet
      keyword_set(sxtp): rd_obs,newstrt, newstop,a,b,data,/nobcs,/nosxtf,/quiet
      keyword_set(bcs):  rd_obs,newstrt, newstop, data,/quiet
      else:              rd_obs,newstrt, newstop, a,b,c,data,/nobcs,/nosxtf,/nosxtp,/quiet
   endcase
endif else begin		; call other rd_xxx routine
   if readnew then begin
      message,/info,"Reading new " + strupcase(prefix) + " data..."
      call_procedure,'rd_' + prefix, newstrt, newstop, data
   endif else  exe=execute('data=' + prefix + 'l')
endelse

; ---------- check for valid data return ---------------
if not data_chk(data,/struct) then begin
   message,/info,"No " + strupcase(prefix) + " data available for specified times"
   return
endif else exe=execute(prefix+'l=data')	; update common block

strt0=newstrt
stop0=newstop

; Now do the processing...
case strupcase(prefix) of
;  ------------------------ Yohkoh Ephemeris Events ------------------
   'FEM': begin
      dayss=anytim2ints(data)
      nightss=anytim2ints(dayss,offset=float(data.night))
      saasss=where(data.st_saa ne 0,saascnt)
      saaess=where(data.en_saa ne 0,saaecnt)
      case 1 of
         contacts: begin
;           using contacts for now, since it does the dirty work
;           expects JST, so need to offset
            contacts,timegrid(strt0,hours=9), timegrid(stop0,hours=9),  $
		/quiet,outstr=outstr, 					  $
	       canberra=canberra, goldstone=goldstone, madrid=madrid
            cols=str2cols(outstr)
            estarts=strsplit(outstr,'(',/head,tail=tail)
            estarts=strsplit(tail,')',/head)             
	    estops=fmt_tim(anytim2ints(estarts, offset = $
	              float((str2cols(strsplit(outstr,')',/tail)))(3,*))*60.))
         endcase
         days: begin
	    estarts=fmt_tim(dayss)
            estops=fmt_tim(nightss)
         endcase
         nights: begin
            estarts=fmt_tim(nightss)
            estops=shift(fmt_tim(dayss),-1)
         endcase
         saas: begin
            nevts=max([saascnt,saaecnt])
            if nevts gt 0 then begin
                estarts=fmt_tim(anytim2ints(data(saasss),offset=data(saasss).st_saa))
                estops= fmt_tim(anytim2ints(data(saaess),offset=data(saaess).en_saa))
            endif
         endcase         
      endcase
   endcase
;  ---------------- Yohkoh Event Log Events ------------------------
   'EVN': begin
;     just grab flare mode ranges...
      estarts=''
      estops=''
      flaress=where(gt_dp_mode(data) eq 9,fcnt)
      if fcnt eq 0 then message,/info, $
	   "No Yohko flare mode in specified time range..." $
      else begin
         estarts=fmt_tim(data(flaress))
         estops= fmt_tim(anytim2ints(estarts,offset=data(flaress).duration))
      endelse
   endcase

;  ------------------------ GOES Events ----------------------------------
   'GEV': begin
       message,/info,"GOES events implemented tommorrow...
;      logic from goes_summary...
       if data_chk(goes,/string) then glevel='A' else glevel=goes
       
   endcase

;  ------------------------ Observing Log ---------------------------------
   'OBS': estarts=data				; just return obs data
endcase
;
if n_params() le 2 then begin	; return in 1st 2 parameters
   starttime=estarts
   stoptime=estops
endif
nevents=n_elements(estarts)
return
end


