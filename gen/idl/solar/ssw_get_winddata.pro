function ssw_get_winddata,t0,t1,json=json, mag=mag, plasma=plasma, url_only=url_only, files_only=file_only, $
   lastn=lastn, minutes=minutes,hours=hours,days=days, parent_url=parent_url, count=count, $
   loud=loud, verbose=verbose,add_acetags=add_acetags,_extra=_extra , dscovr=dscovr, debug=debug
;+
;   Name: ssw_get_winddata
;
;   Purpose: time2 noaa json -> structure vector - ACE & DISCOVR , mag or plasma
;
;   Input Paramters:
;      t0,t1 - user time range (default=last 7 days)
;
;   Ouput: 
;      function returns structure vector, .TIME_TAG=anytim/utplot-ready
;      
;   Keyword Parameters:
;      mag - if set, MAG files/urls (default=PLASMA) 
;      plasma - request PLASMA files/urls (default anyway)
;      url_only - if set, just return implied url ; currently swpc nrt (ne
;      file_only - if set, just return implied filename (in case New parent urls show up?)
;      parent_url - future parents? currently SWPC assumed
;      count - # structures returned
;      loud,verbose (synonum switches) - if set, show some info
;
;   Restrictions:
;      for json parse piece, requires IDL 8.2+
;      for today, SWPC NRT only (last 7 days) - archival/NCEI(formerly NGDC) support when it 
;
;   History:
;      26-Jul-2016 - S.L.Freeland - parse snippets courtesy William Thompson read_noaa_...pro
;                                   Thanks to Nariaki Nitta for reminder ACE->DSCVR transition
;      27-jul-2016 - S.L.Freeland - error checking on bad sock_list,<PARENT_URL>/<file> - add /loud+/verbose
;      21-sep-2016 - S.L.Freeland - add /ADD_ACETAGS switch - included get_acedata tag analogs for down-line apps
;                                   add _extra=_extra so this may serve as get_acedata swap-in (keywords ignored, but no crash)
;      29-nov-2021 - S.L.Freeland - add /DSCOVR keyword and function
;      14-May-2024 - W.T.Thompson - error checking on bad list.toarray
;
;- 

mag=keyword_set(mag) ; user wants MAG
plasma=1-mag        ; default is plasma
count=0 ; as with life, assume failure
loud=keyword_set(loud) or keyword_set(verbose)
dscovr=keyword_set(dscovr)
debug=keyword_set(debug)


now=reltime(/now)

if n_elements(t0) eq 0 then t0=reltime(days=-7)
if n_elements(t1) eq 0 then t1=now

t0x=t0
t1x=t1

dtm=ssw_deltat(t0,now,/minutes)
dth=dtm/60.
dtd=dth/24.
dtt1=ssw_deltat(t1, reltime(days=-7), /hours)

file_only=keyword_set(file_only)
url_only=keyword_set(url_only)

if file_only or url_only then retval='' else retval=-1 ; failure default return values..

case 1 of 
   dtm le 5.05: tunit='5-minute'
   dth le 2.05: tunit='2-hour'
   dth le 6.05: tunit='6-hour'
   dtd le 1.05: tunit='1-day'
   dtd le 7.05: tunit='7-day'
   else: begin
      if dtt1 gt 0 then box_message,'No data in your time range; quicklook only for today..' else begin ; NCEI support soon..
         box_message,'currently only 7 day lookback, trimming accordingly
         tunit='7-day'
      endelse
   endcase 
endcase

if n_elements(tunit) gt 0 then begin 
   if n_elements(parent_url) eq 0 then parent_url='http://services.swpc.noaa.gov/products/solar-wind/' ; SWPC only for today
   file=(['mag','plasma'])(plasma) + '-' + tunit + '.json'
   url=parent_url+(['','/'])(strlastchar(parent_url) ne '/') + file
   if keyword_set(dscovr) then begin 
      box_message,'Using /json/ instead of /products/'
      parent_url= 'https://services.swpc.noaa.gov/json/dscovr/dscovr_mag_1s.json
      url=parent_url
   endif
   case 1 of 
      file_only: retval=file
      url_only: retval=url
      else: begin 
         case 1 of 
            mag: retval={time_tag:'',b_gsm:fltarr(3),lon_gsm:0.,lat_gsm:0.,bt:0.}
            else: retval={time_tag:'',density:0.,speed:0.,temperature:0.}
         endcase
         sock_list,url,json, err=err
         if loud then box_message,['parent_url='+parent_url,'url='+url]
         if err[0] ne '' then begin ; bad sock_list
            box_message,'Bad listing from PARENT_URL='+parent_url+ ' ... returning'
            return,retval ; EARLY EXIT ON BAD PARENT_URL/sock_list
         endif
         list = json_parse(json, /tostruct) ; todo - see why /TOSTRUCT not working out of box (xtra [?)
         if dscovr then begin 
            nr=n_elements(list)
            retval=replicate(list[0],nr)
            for li=0,nr-1 do retval[li]=list[li]

         endif else begin 
            array= list.toarray(missing='NaN')
            sz = size(array)
            if (sz[0] lt 2) or (sz[1] lt 2) then begin
                box_message, 'Bad array from list.toarray ... returning'
                return, retval     ; EARLY EXIT ON BAD ARRAY ;
            endif
            data = float(temporary(array[1:*,*]))
            count=data_chk(data,/nx) ; number of returned elements
            retval=replicate(retval,count)
            retval.time_tag=array[1:*,0]
         endelse
         case 1 of 
;           Thanks to Bill Thompson for array mappings!
            mag: begin 
               retval.b_gsm=transpose(data[*,1:3])
               retval.lon_gsm=data[*,4]
               retval.lat_gsm=data[*,5]
               retval.bt=data[*,6]
            endcase
            dscovr: begin 
              help,retval 
            endcase
            else: begin ; plasma
               retval.density=data[*,1]
               retval.speed=data[*,2]
               retval.temperature=data[*,3]
            endcase
         endcase   
      endcase
   endcase
endif
if debug then stop,'retval,list array
if data_chk(retval,/struct) then begin 
   epoch=ssw_time2epoch(retval.time_tag,t0x,t1x)
   ssok=where(epoch eq 0, count)
   case 1 of 
       count gt 0: retval=retval[ssok]
       else: begin 
          box_message,'No records in your time range...'
          retval=-1
       endcase
    endcase
endif
if data_chk(retval,/struct) and keyword_set(add_acetags) then begin 
   case 1 of 
      required_tags(retval,'density,speed,temperature'): begin 
         retval=add_tag(retval,retval.density,'p_density')
         retval=add_tag(retval,retval.speed,'b_speed')
         retval=add_tag(retval,retval.temperature,'ion_temp')
      endcase
      required_tags(retval,'b_gsm,lon_gsm,lat_gsm'): begin 
         retval=add_tag(retval,reform(retval.b_gsm[0]),'bx')
         retval=add_tag(retval,reform(retval.b_gsm[1]),'by')
         retval=add_tag(retval,reform(retval.b_gsm[2]),'bz')
         retval=add_tag(retval,retval.lon_gsm,'lon')
         retval=add_tag(retval,retval.lat_gsm,'lat')
      endcase
      else:
   endcase
   retval=join_struct(retval,anytim(retval.time_tag,/utc_int))
endif

return,retval
end





