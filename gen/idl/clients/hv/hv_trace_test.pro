
; test script to read and process TRACE images for Helioviewer

pro hv_trace_test,tstart,tend,_ref_extra=extra,out_dir=out_dir
  
common trace_test, tobj

odir=curdir()
if is_string(out_dir) then begin
 mk_dir,out_dir,err=err,path=odir
 if is_string(err) then begin
  mprint,err
  return
 endif
endif

;- initialize TRACE object

if ~obj_valid(tobj) then tobj=obj_new('trace') 

files=tobj->search(tstart,tend,_extra=extra,count=count,/verbose,image_no=image_no)

if count eq 0 then begin
 mprint,'No matching files found.'
 return
endif

;-- read files into memory (just do first one for testing)

count=1
for i=0,count-1 do begin
 tobj->read,files[i],_extra=extra,err=err,/wave2point,/unspike,/destreak,/deripple,image_no=image_no
 if is_string(err) then return
 nimg=tobj->get(/count)
 for j=0,nimg-1 do begin
  tobj->plot,j,/use
  index=tobj->get(j,/index)
  data=tobj->get(j,/data,/no_copy)
  image=tobj->scale(index,data,/log)
  HV_TRACE2_PREP2JP2,index,image,hvs=hvs

  details = hvs.hvsi.details
  jp2_filename = concat_dir(odir,HV_FILENAME_CONVENTION(hvs.hvsi,/create))

  HV_WRITE_JP2_LWG,jp2_filename,hvs.img,hvs.hvsi.write_this,fitsheader = hvs.hvsi.header,$
   details = details,measurement = hvs.hvsi.measurement
 endfor
endfor

return & end
