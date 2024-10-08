;+
; Project     : HESSI
;
; Name        : TRACE__DEFINE
;
; Purpose     : Define a TRACE data object
;
; Category    : Ancillary GBO Synoptic Objects
;
; Syntax      : IDL> c=obj_new('trace')
;
; History     : Written 30 Dec 2007, D. Zarro (ADNET)
;               Modified 8 Sep 2013, Zarro (ADNET) - added CATCH in ::READ
;               5 April 2016, Zarro (ADNET) 
;                - added /NO_PREP, /ALL
;                - added capability to preselect processed level 1
;                  images
;               16-June-2016, Zarro (ADNET)
;                - added support to run read_trace in Windows 32 bit
;               24-March-2017, Zarro (ADNET)
;                - added COLOR support
;               19-July-2017, Zarro (ADNET)
;                - switched default searching to LMSAL
;               31-July-2017, Zarro (ADNET)
;                - fixed typo with prepped data being undefined
;                  because of misplaced /no_copy 
;               4-Jan-2022, Zarro (ADNET) -  added TRACE_SERVER()
;               12-Feb-2022, Zarro (ADNET) - added FLEVEL to ::SEARCH
;               18-Mar-2022, Zarro (ADNET) - added more robust error checking
;
; Contact     : dzarro@solar.stanford.edu
;-

function trace::init,_ref_extra=extra

if ~self->fits::init(_extra=extra) then return,0

;-- setup environment

self->setenv,_extra=extra
self->add_path

return,1 & end

;------------------------------------------------------------------------

pro trace::cleanup

self->binaries,/reset
self->fits::cleanup

return & end

;------------------------------------------------------------------------
;-- setup TRACE environment variables

pro trace::setenv,_extra=extra

if is_string(chklog('TRACE_RESPONSE')) then return

idl_startup=local_name('$SSW/trace/setup/IDL_STARTUP')
if file_test(idl_startup,/reg) then main_execute,idl_startup

file_env=local_name('$SSW/trace/setup/setup.trace_env')
file_setenv,file_env,_extra=extra
return & end

;------------------------------------------------------------------------
;-- return reference to TRACE dbase

function trace::which_dbase,calibration=calibration,lookup=lookup,$
                           dbase_name=dbase_name,dbase_err=dbase_err
  
if keyword_set(calibration) then begin
 dbase_name=local_name('$SSWDB/tdb')
 mklog,'tdb',dbase_name  
 dbase_err='TRACE calibration directory ($SSWDB/tdb) not found. Cannot prep Level 0 file.'
 ref=self.have_cal
endif else begin
 dbase_name=local_name('$SSW/trace/dbase')
 dbase_err='TRACE lookup dbase ($SSW/trace/dbase) not found. Cannot read Level 0 file.'  
 ref=self.have_look
endelse

return,ref
end

;-------------------------------------------------------------------------
;-- check that TRACE Calibration Databases are loaded  

function trace::have_dbase,err=err,verbose=verbose,_extra=extra

verbose=keyword_set(verbose)
ref=self->which_dbase(_extra=extra,dbase_name=dbase_name,dbase_err=dbase_err)

if ref.checked then begin
 err=ref.err
 if verbose then mprint,err  
 return,ref.value
endif
 
err=''
chk=file_test(dbase_name,/dir)
if ~chk then begin
 err=dbase_err
 xack,err,/suppress
 ref.err=err
 ref.value=0
endif else begin
 ref.err=''
 ref.value=1
endelse

ref.checked=1
name=tag_names(ref,/structure_name)
temp=obj_struct(self)
chk=have_tag(temp,name,index,count=count)
if count eq 1 then self.(index)=ref

return,ref.value

end

;-------------------------------------------------------------------------
;-- check for trace_decode_idl shareable object

function trace::have_decoder,err=err,verbose=verbose,_extra=extra

;0  = not found
;1  = found locally
;2  = found remotely

verbose=keyword_set(verbose)  

if self.have_decoder.checked then begin
 err=self.have_decoder.err
 if verbose then mprint,err  
 return,self.have_decoder.value
endif
 
;-- look for it 

err=''
wdir=!version.OS + '_' + !version.ARCH
if self->need_thread() then wdir=str_replace(wdir,'_64','') 
decomp='trace_decode_idl.so'
if os_family() eq 'Windows' then decomp='trace_decode_idl.dll'
share=local_name('$SSW_TRACE/binaries/'+wdir+'/'+decomp)
chk=file_test(share)

;-- found local copy

if chk then begin
 self.have_decoder.value=1
 self.have_decoder.checked=1
 self.have_decoder.err=''
 return,self.have_decoder.value
endif

;-- try to download a copy to temporary directory

warn='TRACE decompressor not found.'
if verbose then mprint,warn+' Attempting download from SSW server...'
sdir=get_temp_dir()
tdir=concat_dir(sdir,'exe')
udir=concat_dir(tdir,wdir)
mk_dir,udir,/a_write,/a_read
sloc=ssw_server(/full)
sfile=sloc+'/solarsoft/trace/binaries/'+wdir+'/'+decomp
sock_get,sfile,out_dir=udir,_extra=extra,/no_check,local=share
chk=file_test(share)
if chk then begin
 if verbose then mprint,'Download succeeded.'
 mklog,'SSW_BINARIES_SAVE',chklog('SSW_BINARIES')
 mklog,'SSW_BINARIES_TEMP',sdir
 mklog,'SSW_BINARIES',sdir
 self.have_decoder.value=2
 self.have_decoder.checked=1
 self.have_decoder.err=''
 return,self.have_decoder.value
endif 

err=warn+' Cannot read Level 0 file.'
xack,err,/suppress
self.have_decoder.err=err
self.have_decoder.value=0b
self.have_decoder.checked=1b

return,self.have_decoder.value

end

;-------------------------------------------------------------------------

function trace::time2week,t1,t2,time_id=time_id

week_id='' & time_id=''
if ~valid_time(t1) then return,week_id
if ~valid_time(t2) then t2=t1
t1c=anytim2utc(t1,/ecs)
t2c=anytim2utc(t2,/ecs)
grid=timegrid(t1c,t2c,/hours,/string,/quiet)
week_id=anytim2weekinfo(grid,/first)
yymmdd=time2fid(grid,/full)
ext=anytim2utc(grid,/ext)
hr=string(ext.hour,'(i2.2)')+'00'
time_id=yymmdd+'.'+hr
return,week_id
end

;--------------------------------------------------------------------------

function trace::mission_times,ecs=ecs

tstart='16-Feb-1998 20:00:00.000'
tend='22-Jun-2010 00:00:00.000'
trange=[tstart,tend]
if keyword_set(ecs) then return,trange else return,anytim2tai(trange)
end

;--------------------------------------------------------------------------

function trace::overlap,tstart,tend,dstart=dstart,dend=dend

dstart=-1.d & dend=-1.d
if ~valid_time(tstart) || ~valid_time(tend) then return,0b

mtimes=self->mission_times()
mstart=mtimes[0] & mend=mtimes[1]
times=anytim2tai([tstart,tend])
dstart=min(times) & dend=max(times)
outside= ((dstart lt mstart) && (dend lt mstart)) || $
         ((dstart gt mend) && (dend gt mend))

if ~outside then begin
 dstart =  dstart > mstart
 dend = dend < mend
endif

return,~outside
end

;--------------------------------------------------------------------------

function trace::search,tstart,tend,_ref_extra=extra,vso=vso,flevel=flevel,cat=cat
  
vso=keyword_set(vso)
cat=keyword_set(cat)  
if ~is_number(flevel) then flevel=0 else flevel= 0 > fix(flevel) < 1

;-- def search for Level 0 files

methods=['level0','level1','vso','cat']
case 1 of
 cat: method=methods[3]
 flevel eq 1: method=methods[1] 
 vso: method=methods[2]
 else: method=methods[0]
endcase

files=call_method(method,self,tstart,tend,_extra=extra)

return,files
end

;-------------------------------------------------------------------------
;-- LMSAL search wrapper

function trace::level1,tstart,tend,_ref_extra=extra,wave=wave,count=count,type=type,verbose=verbose,err=err
verbose=keyword_set(verbose)
if verbose then mprint,'Searching for Leve1 1 files...'

self->valid_times,tstart,tend,err=err
if is_string(err) then return,''

server=trace_server(_extra=extra,path=path,flevel=1)
s=obj_new('site')
s->setprop,rhost=server,topdir=path,/full,ext='fts',delim='/'
if keyword_set(wave) then s->setprop,ftype='.'+trim(wave)
files=s->search(tstart,tend,_extra=extra,count=count)
obj_destroy,s

type=self->ftype(count)
return,files
end

;------------------------------------------------------------------------
;-- return image type 

function trace::ftype,count

type='euv/images'
if ~is_number(count) then return,''
if count eq 0 then return,''
if count eq 1 then return,type
return,replicate(type,count)

end
 
;------------------------------------------------------------------------
;-- return TAI times of files based on filename

function trace::ftimes,files,_extra=extra

if is_blank(files) then return,-1
count=n_elements(files)
times=parse_time(files,_extra=extra,/tai)
if count eq 1 then times=times[0]

return,times
end

;-----------------------------------------------------------------------
;-- search local archive before remote archive

function trace::cat_search,tstart,tend,_ref_extra=extra

if self->have_level0() then files=self->cat(tstart,tend,_extra=extra) else $
 files=self->level0(tstart,tend,_extra=extra,/verb)

return,files
end
  
;------------------------------------------------------------------------
;-- search TRACE catalog

function trace::cat,tstart,tend,count=count,err=err,type=type,times=times,verbose=verbose,_ref_extra=extra

verbose=keyword_set(verbose)
if verbose then mprint,'Searching catalog for Level 0 files...'
count=0
err=''
return_times=arg_present(times)
times=-1
type=self->ftype()
self->valid_times,tstart,tend,err=err
if is_string(err) then return,''

path=self->level0_dir()
if is_blank(path) then begin
 err='Local Level 0 archive environment ($TRACE_I1_DIR) not defined.'
 mprint,err
 return,''
endif

if ~self->have_level0(err=err) then return,''

trace_cat, tstart,tend, catalog, status=status,loud=verbose
if status eq 0 then return,''

trace_cat2data,catalog,files,-1,/filedset,loud=verbose
count=n_elements(files)
type=self->ftype(count)
if return_times then times=self->ftimes(count)
return,files
end

;------------------------------------------------------------------------
;-- check for local Level 0 archive

function trace::level0_dir
  
return,chklog('TRACE_I1_DIR')

end

;----------------------------------------------------------------------------
function trace::have_level0,err=err,verbose=verbose

err=''
verbose=keyword_set(verbose)
ldir=self->level0_dir()

if is_blank(ldir) then begin
 err='Local Level 0 archive environment variable ($TRACE_I1_DIR) is not defined.'
 mprint,err  
 return,''
endif

if ~file_test2(ldir,/dir) then begin
 err='Local Level 0 archive ('+ldir+') is not a directory.'
 mprint,err  
 return,''
endif

if ldir ne self.have_level0.last then self.have_level0.checked=0b
if self.have_level0.checked then begin
 err=self.have_level0.err
 mprint,err
 return,self.have_level0.value
endif

;-- look for weekly directories

weeks=file_search(concat_dir(ldir,'week*'),count=count,/expand_environment,/test_directory)
if count gt 0 then begin
 chk=stregex(weeks[0],'.*(week[0-9]{8})',/bool)
 if ~chk then count=0
endif

if count eq 0 then begin
 err='Level 0 files not found locally in - '+ldir
 mprint,err
 self.have_level0.err=err
 self.have_level0.value=0b
endif else begin
 self.have_level0.err=''
 self.have_level0.value=1b
endelse

self.have_level0.last=ldir
self.have_level0.checked=1b
return,self.have_level0.value

end
  
;------------------------------------------------------------------------
;-- validate input times

pro trace::valid_times,tstart,tend,err=err,_extra=extra

err=''
if valid_time(tstart) && ~valid_time(tend) then begin
 dstart=get_def_times(tstart,dend=dend,_extra=extra,/ecs)
 tstart=dstart & tend=dend 
endif else begin
 if ~valid_time(tstart) && ~valid_time(tend) then begin
  err='Invalid search times.'
  mprint,err
  return
 endif
endelse

overlap=self->overlap(tstart,tend,dstart=dstart,dend=dend)
if ~overlap then begin
 err='Search times outside mission lifetime.'
 mprint,err
 mtimes=self->mission_times(/ecs)
 print,'   '+mtimes[0]+' -> '+mtimes[1]
endif else begin
 tstart=anytim2utc(dstart,/ecs) & tend=anytim2utc(dend,/ecs)
endelse  
   
return & end
;-------------------------------------------------------------------------
;-- find  Level 0 files

function trace::level0,tstart,tend,_ref_extra=extra,verbose=verbose,count=count,$
                       times=times,type=type,err=err,nearest=nearest

err=''
verbose=keyword_set(verbose)
nearest=keyword_set(nearest)
if verbose then mprint,'Searching remote archive for Level 0 files...'
return_times=arg_present(times)
times=-1
count=0l
type=''
self->valid_times,tstart,tend,err=err
if is_string(err) then return,''

server=trace_server(flevel=0,path=path,err=err,verbose=verbose)
if is_string(err) then return,''
path=server+path
tstart=anytim2tai(tstart) & tend=anytim2tai(tend)

week_id='week'+self->time2week(tstart,tend,time_id=time_id)

;-- gather list of actual files on server

wpath=path+'/'+week_id
upath=get_uniq(wpath)
for i=0,n_elements(upath)-1 do begin
 ufiles=sock_find(upath[i],'tri*',count=ucount)
 if ucount gt 0 then tfiles=append_arr(tfiles,ufiles,/no_copy)
endfor

count=n_elements(tfiles)
if count eq 0 then begin
 mprint,'No matching files found.'
 return,''
endif

;-- match against selected times

sfiles=path+'/'+week_id+'/tri'+time_id
files=str_same(sfiles,tfiles,count=count)

if count eq 0 then begin
 mprint,'No matching files found.'
 return,''
endif

if nearest then begin
 nfile=self->nearest(files,tstart,count=count,err=err,_extra=extra)  
 if count eq 0 then begin
  mprint,'No matching files found.'
  return,''
 endif else files=nfile
endif

type=self->ftype(count)
if return_times then times=self->ftimes(files,delim='.')  
return,files
end

;-------------------------------------------------------------------------
;-- find Level 0 file with nearest matching time and matching
;   wavelength (optional)

function trace::nearest,files,tstart,err=err,count=count,_extra=extra,$
                        wavelength=wavelength,image_no=image_no,dimensions=dimensions
  
err='' & count=0 & image_no=-1
if ~valid_time(tstart) || is_blank(files) then return,''
nweek=self->time2week(tstart,time_id=ntime)
ftimes=stregex(files,'.+tri(.+)',/sub,/ext)
chk=where(ftimes[1,*] eq ntime,ncount)
if ncount eq 0 then begin
 err='No nearest time found.'
 mprint,err
 return,''
endif

nfile=files[chk[0]]

self->read,nfile,-1,index=index,err=err
if is_string(err) then begin
 mprint,err
 return,''
endif

otimes=anytim2tai(index.date_obs) & itime=anytim2tai(tstart)
oimage=indgen(n_elements(otimes))

swave=0b
if exist(wavelength) then begin
 iwave=strupcase(strtrim(wavelength,2))
 owave=strupcase(strtrim(index.wave_len,2))
 werr='No images matching wavelength - '+iwave
 wchk=where(iwave eq owave,wcount)
 if wcount eq 0 then begin
  count=0
  err=werr & mprint,err
  return,''
 endif
 swave=1b
endif

sdim=0b
if (n_elements(dimensions) gt 0) then begin
 dim1=dimensions[0] & dim2=dim1
 derr='No images matching dimensions - '+strtrim(dim1,2)+','+strtrim(dim2,2)
 dchk=where( (dim1 eq index.naxis1) and (dim2 eq index.naxis2),dcount)
 if dcount eq 0 then begin
  count=0
  err=derr & mprint,err
  return,''
 endif
 sdim=1b
endif

if sdim || swave then begin
 case 1 of
  swave && sdim: begin
   chk=where( (iwave eq owave) and (dim1 eq index.naxis1) and (dim2 eq index.naxis2),count)
   if count eq 0 then begin
    err=[werr,derr] & mprint,err
    err=strjoin(err,' ,')
    return,''
   endif
  end
  swave && ~sdim: begin 
   chk=wchk & count=wcount
  end
  sdim && ~swave: begin
   chk=dchk & count=dcount 
  end
  else: begin
   err='Weird error.' & mprint,err
   count=0
   return,''
  end
 endcase
 otimes=otimes[chk] & oimage=oimage[chk]
endif

image_no=oimage

if count gt 1 then return,nfile
  
diff=abs(otimes-itime)
found=where(diff eq min(diff),count)
image_no=image_no[found[0]]

return,nfile
end
  
;--------------------------------------------------------------------------
;-- VSO search wrapper

function trace::vso,tstart,tend,_ref_extra=extra,type=type,count=count,verbose=verbose
if keyword_set(verbose) then mprint,'Searching VSO...'
files=vso_files(tstart,tend,inst='trace',_extra=extra,window=3600.,/recover_url,count=count)
type=self->ftype(count)
return,files
end

;---------------------------------------------------------------------------
;-- add TRACE path

pro trace::add_path

if ~have_proc('read_trace') then begin
 epath=local_name('$SSW/trace/idl')
 if file_test(epath,/dir) then ssw_path,/trace,/quiet
endif

return
end

;---------------------------------------------------------------------------
;-- check for TRACE branch in !path

function trace::have_path,err=err,verbose=verbose

verbose=keyword_set(verbose)
if self.have_path.checked then begin
 err=self.have_path.err
 if verbose then mprint,err  
 return,self.have_path.value
endif

err=''
self->add_path
if ~have_proc('read_trace') then begin
 err='TRACE branch of $SSW not installed. Cannot read or prep Level 0 file.'
 self.have_path.err=err
 xack,err,/suppress
 self.have_path.value=0b
endif else begin
 self.have_path.err=''
 self.have_path.value=1b
endelse

self.have_path.checked=1b
return,self.have_path.value

end

;--------------------------------------------------------------------------
;-- FITS reader

pro trace::read,file,data,_ref_extra=extra,image_no=image_no,err=err,$
                all=all,no_prep=no_prep,index=index

err=''

;-- download if URL

if is_blank(file) then begin
 pr_syntax,'object_name->read,filename'
 return
endif

self->getfile,file,local_file=ofile,_extra=extra,err=err,count=count
if count eq 0 then return

self->empty
do_all=keyword_set(all)
do_img=0b
if exist(image_no) then begin
 if is_number(image_no[0]) then begin
  chk=where(image_no gt -1,icount)
  do_img=icount gt 0
 endif
endif 

do_select=~do_all
do_prep=~keyword_set(no_prep)

;-- read files

nfiles=n_elements(ofile)
j=0
self->binaries

cd,cur=cdir
for i=0,nfiles-1 do begin
 err=''
 dfile=ofile[i]

 valid=self->is_valid(dfile,level=level,_extra=extra,err=err,decomp=decomp)
 if ~valid then continue

;-- if level 1 then read with FITS object

 if level eq 1 then begin
  self->fits::read,dfile,data,extension=image_no,select=do_select,_extra=extra,index=index
  count=self->get(/count)
  for kk=0,count-1 do begin
   log_scale=is_number(index[kk].wave_len)
   self->set,log_scale=log_scale
  endfor
  j=count+1
  continue
 endif

;-- warn if key calibration and prep files are missing

 if level eq 0 then begin
  if ~self->have_path(err=path_err,/verbose) then continue
  if ~decomp then begin
   if ~self->have_decoder(err=decoder_err,/verbose) then continue
   if ~self->have_dbase(err=dbase_err,/verbose,/lookup) then continue
  endif
 endif

;-- just need index

 if level eq 0 then begin
  if is_number(data) then begin
   read_trace,dfile,-1,index,/nodata,/quiet
   if data eq -1 then return
   if (data gt -1) && (data lt n_elements(index)) then index=index[data] else index=-1
   return
  endif
 endif

;-- select image subset?
 
 records=self->read_records(dfile,count=n_img)
 if n_img eq 0 then continue
 images=indgen(n_img)
 if do_img then begin
  match,images,image_no,p,q
  if p[0] eq -1 then begin
   mprint,'No matching images in '+dfile
   continue
  endif
  image_no=p
 endif else image_no=images 
 
;-- preselect? 
 
 if ~do_all then begin
  if n_elements(image_no) gt 1 then begin
   self->preselect,dfile,sel_no,cancel=cancel,/no_counter,input_no=image_no
   if (cancel eq 1) || (sel_no[0] eq -1) then continue
   image_no=sel_no
  endif 
 endif
  
;-- if level 0 then read use TRACE reader
  
 nimg=n_elements(image_no)
 for k=0,nimg-1 do begin
  err=''
  oindex=-1 & odata=-1
  img=image_no[k]
  mprint,'Reading image '+trim(img)
  if decomp then self->fits::read,dfile,odata,index=oindex,exten=img,err=err,_extra=extra else $
   self->read_comp,dfile,img,oindex,odata,_extra=extra,err=err
  
  if is_string(err) then begin
   mprint,err
   continue
  endif

  sz=size(odata)
  if (sz[0] lt 2) then begin
   err='Image '+trim(img)+' is not 2-D.'
   print,sz  
   mprint,err
   continue
  endif

  if do_prep then do_prep=self->have_dbase(err=dbase_err,/verbose,/calibration)
  if do_prep then begin
   mprint,'Prepping image '+trim(img)
   extra=rem_dup_keywords(extra)  
   trace_prep,oindex,odata,pindex,pdata,/norm,/wave2point,/float,_extra=extra,/quiet
   if ~is_struct(pindex) then begin
    err='Error prepping image '+trim(img)
    mprint,err
    continue
   endif
  endif else begin
   pindex=oindex & pdata=temporary(odata)
  endelse

  pindex=rep_tag_value(pindex,2l,'naxis')
  log_scale=is_number(pindex.wave_len)
  id='TRACE '+trim(pindex.wave_len)+' ('+trim(pindex.naxis1)+'x'+trim(pindex.naxis2)+')'
  self->mk_map,pindex,pdata,j,_extra=extra,filename=dfile,id=id,err=err,log_scale=log_scale,/no_copy
  if is_string(err) then continue
  j=j+1
 endfor
endfor

count=self->get(/count)
if count eq 0 then begin
 err1='No maps created.'
 if is_string(err) then err=err1+' '+err else err=err1
 mprint,err,/info 
endif

self->binaries,/reset

return & end

;--------------------------------------------------------------------
;-- return byte-scaled data

function trace::scale,index,data,outindex,_extra=extra,log=log

if (size(data,/n_dim) ne 2) then if exist(data) then return,data else return,-1
if ~is_struct(index) then return,data
do_log=keyword_set(log) && index.wave_len ne 'WL'
return,cscale(data,_extra=extra,log=do_log)

if ~have_proc('trace_scale') then return,data
if n_params() eq 2 then return,call_function('trace_scale',index,data,/byte,_extra=extra)
if n_params() eq 3 then return,call_function('trace_scale',index,data,outindex,/byte,_extra=extra)
return,data
end

;--------------------------------------------------------------------

;-- redirect TRACE binaries directory to temporary location if downloading DLL decoder

pro trace::binaries,reset=reset

if self.have_decoder.value ne 2 then return

if keyword_set(reset) then begin
 if is_string(chklog('SSW_BINARIES_SAVE')) then mklog,'SSW_BINARIES','SSW_BINARIES_SAVE'
endif else begin
 if is_string(chklog('SSW_BINARIES_TEMP')) then mklog,'SSW_BINARIES',chklog('SSW_BINARIES_TEMP')
endelse

return & end

;-------------------------------------------------------------------
;-- check if need to use 32 bit thread on 64 bit system

function trace::need_thread
mbits=!version.memory_bits
return,(os_family(/lower) eq 'windows') && (mbits eq 64)
end

;-----------------------------------------------------------------------

pro trace::read_comp,dfile,img,oindex,odata,_extra=extra,ops=ops,err=err,thread=thread

err=''
oindex=-1 & odata=-1

cdir=curdir()
error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 message,/reset
 error=0
 cd,cdir
 return
endif

;-- if Windows 64 bit, run read_trace in 32 bit thread

if keyword_set(thread) then begin
 if ~is_number(ops) then ops=64
endif else ops=32

if self->need_thread() || keyword_set(thread) then begin
 thread,ops=ops,err=err,_extra=extra,output=concat_dir(get_temp_dir(),'bridge.txt'),switched_thread=switched
 if is_string(err) then begin
  err='Cannot decompress TRACE image on this system.'
  mprint,err
  return
 endif
 if ~self.thread || switched then begin
  thread,'void=obj_new','trace',/wait
  if self.have_decoder.value eq 2 then thread,'mklog','SSW_BINARIES',chklog('SSW_BINARIES_TEMP'),/wait
  self.thread=1b
 endif
 fdir=file_dirname(dfile)
 if (fdir eq '') || (fdir eq '.') then dfile=concat_dir(curdir(),dfile)
 thread,'read_trace',dfile,img,oindex,odata,_extra=extra,/quiet,/wait
endif else read_trace,dfile,img,oindex,odata,/quiet,_extra=extra

return & end

;-----------------------------------------------------------------------------
;--- read raw records in a TRACE level 0 file

function trace::read_raw,file,err=err

err=''
error=0
catch,error
if error ne 0 then begin
 err=err_state()
 mprint,err,/info
 catch,/cancel
 message,/reset
 return,''
endif

if is_blank(file) then return,''
if is_url(file) then sock_fits,file,data,extension=1,err=err else data=mrdfits(file,1)
if is_string(data) then data=fitshead2struct(data)
if ~is_struct(data) then begin
 if is_blank(err) then err='Failed to read header.'  
 return,''
endif

count=n_elements(data)
index={naxis1:0l,naxis2:0l,date_obs:0d,wave_len:''}
index=replicate(index,count)
index.naxis1=data.nx_out
index.naxis2=data.ny_out
index.wave_len='???'
index.date_obs=anytim(data,/tai)
return,index

end
 
;-------------------------------------------------------------------------
;-- read TRACE level 0 records

function trace::read_records,file,count=count,_ref_extra=extra

count=0
records=''
valid=self->is_valid(file,level=level,decomp=decomp)

if (level eq 0) && ~decomp then begin 
 if self->have_path() && ~is_url(file) then read_trace,file,-1,index,/nodata,/quiet else index=self->read_raw(file,_extra=extra)
endif else self->fits::read,file,index=index,/nodata,_extra=extra

if ~is_struct(index) then return,''
count=n_elements(index)
return,self->format_list(index)
end

;------------------------------------------------------------------------------
;-- check if valid TRACE file

function trace::is_valid,file,err=err,level=level,verbose=verbose,$
                 decompressed=decompressed

valid=0b & level=0 & err=''
decompressed=0b
verbose=keyword_set(verbose)
if is_url(file) then sock_fits,file,header=header,/nodata,err=err else $
 mrd_head,file,header,err=err
if is_string(err) then begin
 mprint,'Could not read header - '+file,/info
 return,valid
endif

chk1=where(stregex(header,'MPROGNAM.+TR_REFORMAT',/bool,/fold),count1)
chk2=where(stregex(header,'(INST|TEL|DET|ORIG).+TRAC',/bool,/fold),count2)
chk3=where(stregex(header,'TRACE_PREP|tr_dark_sub|tr_flat_sub',/bool,/fold),count3)
valid=(count1 ne 0) || (count2 ne 0)

if ~valid then begin
 mprint,'Not a valid TRACE file - '+file,/info
 return,valid
endif

if (count1 ne 0) then level=0 
if (count3 ne 0) then level=1
if (count1 eq 0) then decompressed=1b

if verbose && (level eq 1) then mprint,'TRACE image is already prepped.',/info

return,valid
end

;----------------------------------------------------------------
function trace::have_colors,index,red,green,blue

common trace_colors,scolors

if ~have_proc('trace_colors') then return,0b
if ~is_struct(index) then return,0b
if ~have_tag(index,'wave_len') then return,0b
if ~is_number(index.wave_len) then return,0b

if is_struct(scolors) then begin
 chk=where(index.wave_len eq scolors.wave_len,count)
 if count eq 1 then begin
  red=(scolors[chk]).red
  green=(scolors[chk]).green
  blue=(scolors[chk]).blue
  return,1b
endif
endif

dsave=!d.name
set_plot,'Z'
tvlct,r0,g0,b0,/get
trace_colors,fix(index.wave_len),red,green,blue
tvlct,r0,g0,b0
set_plot,dsave

colors={wave_len:index.wave_len,red:red,green:green,blue:blue}
scolors=merge_struct(scolors,colors)

return,1b & end

;------------------------------------------------------------------------------
;-- TRACE structure definition

pro trace__define,void                 

path={have_path,checked:0b,err:'',value:0b}
cal={have_cal,checked:0b,err:'',value:0b}  
look={have_look,checked:0b,err:'',value:0b}
decoder={have_decoder,checked:0b,err:'',value:0}
level0={have_level0,checked:0b,err:'',value:0,last:''}

void={trace,thread:0b,have_level0:level0,have_cal:cal,have_look:look,have_decoder:decoder,have_path:path,inherits fits, inherits prep}

return & end
