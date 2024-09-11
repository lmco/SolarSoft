

pro hv_beacon,dstart,dend,ndays_back=ndays_back,_ref_extra=extra,err=err,verbose=verbose,copy2outgoing=copy2outgoing,overwrite=overwrite,max_files=max_files

common hv_beacon,beacon
  
err=''
verbose=keyword_set(verbose)  
copy2outgoing=keyword_set(copy2outgoing)
overwrite=keyword_set(overwrite)
if ~is_number(ndays_back) then ndays_back=0

if valid_time(dstart) && valid_time(dend) then begin
 fstart=anytim2utc(dstart) & fend=anytim2utc(dend)
endif else begin
 if valid_time(dstart) then utc=anytim2utc(dstart) else begin
  get_utc,utc & utc.time=0
 endelse  
 fend=utc
 fend.mjd=fend.mjd+1
 fstart=utc
 fstart.mjd=fstart.mjd-ndays_back
endelse

;-- search for BEACON files

if verbose then mprint,'Searching from - '+anytim2utc(fstart,/ecs)+' to '+anytim2utc(fend,/ecs)
if ~obj_valid(beacon) then beacon=obj_new('beacon')
flist=beacon->search(fstart,fend,count=count,_extra=extra)
if count eq 0 then begin
 mprint,'No files found.'
 return
endif

;-- download, check if processed, and prep

error=0
catch,error
if (error ne 0) then begin
 err=err_state()
 catch, /cancel
 message,/reset  
 mprint,err
 if is_windows() then set_plot,'WIN' else set_plot,'X'
endif

if is_number(max_files) then count=max_files > 0L

for i=0,count-1 do begin
 sock_get,flist[i],out_dir=session_dir(),local=local
 if is_blank(local) then continue
 if verbose then mprint,'Reading - '+file_basename(local)

;-- check if JP2 file exists before prepping/writing

 hvs=hv_euvi_hvs(local)
 details = hvs.hvsi.details
 storage = hv_storage(hvs.hvsi.write_this,nickname=details.nickname)
 loc = hv_write_list_jp2_mkdir(hvs.hvsi,storage.jp2_location)
 filename = hv_filename_convention(hvs.hvsi,/create)
 jp2_filename = concat_dir(loc,filename)+'.jp2'
 chk=file_test2(jp2_filename)

;-- prep and write
 
 if ~chk || overwrite then begin
  if !d.name ne 'Z' then set_plot,'Z'
  hv_euvi_prep2jp2,local,_extra=extra,/overwrite
  chk=file_test2(jp2_filename)
  if chk then cfiles=append_arr(cfiles,jp2_filename)
 endif

endfor

nfiles=n_elements(cfiles)
if nfiles eq 1 then cfiles=[cfiles]

if (nfiles gt 0) then hv_copy2outgoing,cfiles,'stereo',_extra=extra
if is_windows() then set_plot,'WIN' else set_plot,'X'
mprint,'# of JP2 files prepped/written = '+trim(nfiles)

return & end
