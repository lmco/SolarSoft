pro show_pix_event,event
;
;+
;   Name: show_pix_event
;
;   Purpose: event driver for xshow_pix
;
;   History:
;      20-Dec-1993 (SLF) (guts of show_pix.pro, 10-Nov)
;   
;-
widget_control,event.top,get_uvalue=top_struct
wchk=where(tag_names(top_struct) eq 'BASE')
main=wchk(0) eq 0
files=get_wuvalue(top_struct.allfiles)
subdir=get_wuvalue(top_struct.subdir)
file=get_wuvalue(top_struct.file)

case (strtrim(event_name(event),2)) of
   "BUTTON":begin                               ; option selection
      case strupcase(get_wvalue(event.id)) of
         "QUIT": begin
		widget_control, top_struct.captbase,/destroy
		widget_control, event.top,/destroy
	    endcase
         "XLOADCT": xloadct, group=event.top
	 "DELETE LAST": if !d.window ne -1 then wdelete
	 "HARD COPY": begin
	       tbeep
	       message,/info,'Not yet implemented'
            endcase
	  "SHOW IMAGE": begin
		widget_control,top_struct.modebuts(0), 	set_uvalue=event.select
	     endcase
	  "SHOW DOCUMENTATION" : begin
		widget_control,top_struct.modebuts(1), set_uvalue=event.select
	        mapx,top_struct.captbase,show=event.select, $
		   map=event.select, sens=event.select
	     endcase
          else: message,/info,"UNKNOWN BUTTON"
       endcase
   endcase 
   "LIST": begin
      cfiles=get_wuvalue(event.id)
      subdir=get_wuvalue(top_struct.subdir)
      filen=get_wuvalue(top_struct.file)
      break_file,files,alog,apath,afiles,aext,aver
      chksub = wc_where(afiles,cfiles(0),cnt)
      case cnt of
         0: begin
	       new=wc_where(files, cfiles(event.index) + '*',cnt)
               widget_control, top_struct.flist, set_value=afiles(new), $
		  set_uvalue=afiles(new)
	       widget_control,top_struct.subdir, set_uvalue=cfiles(event.index)
	       message,/info,'subdirectory' + cfiles(event.index)
	    endcase
         else: begin
	          which = wc_where(afiles,cfiles(event.index),cnt)
		  modes=get_wuvalue(top_struct.modebuts)
                  if cnt gt 0 then begin
		     widget_control,top_struct.current, set_value=files(which)
		     if modes(1) then widget_control,/realize, $
			top_struct.captbase
		     widget_control,top_struct.capttext, set_value= $
			[strarr(10),'...READING IMAGE FILE, PLEASE BE PATIENT']
		     mapx,event.top,/map,/show,sensitive=0
		     restgen,image,r,g,b,nodata=1-modes(0),text=text, $
			file=files(which(0))
		     mapx,event.top,/map,/show,sensitive=1
		     if n_elements(text) eq 1 and text(0) eq '' then $
			text='NO CAPTION AVAILABLE'
		     widget_control, top_struct.capttext, set_value=text
		     if modes(0) and n_elements(image) ne 0 then begin
			simage=size(image)
			if abs(!d.y_size - simage(2)) gt 10 or $
			   !d.x_size lt simage(1) then $
				wdef,wind,/ur,simage(1),simage(2)
		        if data_chk(r,/defined) and data_chk(g,/defined) and $
				data_chk(b,/defined) then tvlct,r,g,b
      			tv,image
			mapx,/show,/map,/sens,event.top
		        mapx,/show,/map,/sens,top_struct.captbase
	             endif	             
		  endif
	       message,/infor,'file' + cfiles(event.index)
	    endcase
      endcase
   endcase
endcase

widget_control,event.top, set_uvalue=top_struct, bad_id=destroyed

return
end

