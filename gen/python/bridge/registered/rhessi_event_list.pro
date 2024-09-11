

pro rhessi_event_list,file,_ref_extra=extra,err=err,thread=thread

err=''
if is_blank(file) then begin
 err='Need output file name.'
 mprint,err
 return
endif

tdir=file_dirname(file)
if ~is_blank(tdir) && (tdir ne '.') then begin
 mk_dir,tdir,/a_write,/a_read,err=err
 if is_string(err) then begin
  mprint,err & return
 endif
endif

if ~file_test(tdir,/dir,/write) then begin
 err='No write access to - '+tdir
 mprint,err
 return
endif

if keyword_set(thread) then begin
 thread,'out=hsi_mk_calib_eventlist',cbe=file,_extra=extra,/new
 return
endif

out=hsi_mk_calib_eventlist(cbe=file,_extra=extra)

return

end
