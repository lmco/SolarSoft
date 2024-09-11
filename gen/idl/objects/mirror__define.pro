;+
; Project     : VSO
;
; Name        : MIRROR__DEFINE
;
; Purpose     : Define a Mirror class to mirror files and/or directories
;               from a source to a target site
;
; Category    : utility system sockets objects
;
; Syntax      : IDL> m=mirror()
;               
;               Set/change source/target
;               IDL> m->set,source=source,target=target 
;
;               Run and recurse over subdirectories
;               IDL> m->mirror,/recurse,/run
;
;               Read and run from a package file
;               IDL> m->mirror,'package.txt',/run
;
; Example     : IDL> m=mirror()
;               IDL> source='https://sohowww.nascom.nasa.gov/solarsoft/gen/idl'
;               IDL> target='$SSW/gen/idl'
;               IDL> m->mirror,source,target
;               or
;               IDL> m->set,source=source,target=target
;               IDL> m->mirror,/run,/recurse,/verbose
;
; Init Inputs : SOURCE = source site to mirror from (directory or URL)
;               TARGET = target site to mirror to (writeable directory)
; 
; Run inputs  : PACKAGE = package file (similar to PERL/MIRROR)  
;
; Outputs     : None
;
; Keywords    : ERR = error string
;               RUN = set to actually execute mirror
;               RECURSE = set to recurse over directories
;               DIRECTORY_ONLY = set to only compare/mirror directories
;               NO_DELETES = set to not delete target files/directories
;               (update only)
;               KEEP_DIRECTORY = do not delete target directories
;               SKIP_DIRECTORIES = Regexp of source directories to not
;               mirror (target directories will be deleted unless
;               KEEP_DIRECTORY is set)
;               IGNORE_FILES = Regexp of source files to not mirror (target files will be deleted)
;               VERBOSE = print progress
;               Legacy Perl/Mirror:
;               GET_PATT = Regexp of source pathnames to retrieve
;               EXCLUDE_PATT = Regexp of source pathnames to exclude
;               LOCAL_IGNORE = Regexp of target pathnames to
;               ignore. Useful to skip restricted target directories
;               NO_CACHE = don't check last cache. Mirror will
;               save a snapshot of the last target and source files
;               for each directory it mirrors. It will check this
;               cache to speed up mirroring next time. You can
;               override this checking by setting /NO_CACHE
;               FORCE = force mirroring regardless of file size or
;               time. This will set /NO_CACHE=1 and essentially
;               re-mirror everything from scratch.
;               DETAILS = set for more detailed progress (1,2 for more detail)
;
;
; History     : 31-Dec-2018, Zarro (ADNET/GSFC) 
;                - first written during 2019 Gov't shutdown
;                - designed to emulate Perl/Mirror 
;               18-Jul-2019, Zarro (ADNET/GSFC)
;                - added Windows support
;               10-Jan-2020, Zarro (ADNET)
;                - vectorized and accelerated with REM_ELEM (thanks Richard!)
;                6-May-2020, Zarro (ADNET)
;                - added caching of file time stamps to speed processing
;               27-Oct-2020, Zarro (ADNET)
;                - vectorized further
;                3-Jan-2021, Zarro (ADNET)
;                - used HASH for faster caching of search results
;                5-May-2022, Zarro (ADNET)
;                - fixed bug with HASH (after extended pandemic-related hiatus)
;
;------------------------------------------------------------------

function mirror::init,source,target,_ref_extra=extra                                                                   

self.sfiles=ptr_new('',/all)
self.tfiles=ptr_new('',/all)
self.sdirs=ptr_new('',/all)
self.tdirs=ptr_new('',/all)
self.new=ptr_new('',/all)
self.old=ptr_new('',/all)
self.diff=ptr_new('',/all)
self.ulist=ptr_new('',/all)
self.slist=ptr_new('',/all)
self.log=ptr_new('',/all)
self.do_directory=1b
self->set,source=source,target=target,_extra=extra
self.file_cache=hash()
self.dir_cache=hash()
self.fhash=hash()
self.dhash=hash()

return,1                                                                                          
end     

;-------------------------------------------------------------------------
pro mirror::mirror,source,target,_extra=extra,err=err,run=run,$
                directory_only=directory_only,append=append,$
                recurse=recurse,log=log

err=''
main=~stregex(get_caller(),'\:\:mirror',/fold,/bool) 
if main then stime=anytim2tai(!stime)
run=keyword_set(run)
directory_only=keyword_set(directory_only)
recurse=keyword_set(recurse)
self->reset

if isa(source,/string) && isa(target,/string) then begin
 self->set,source=source,target=target,err=err
 if is_string(err) then return
endif 

if isa(source,/string) && is_blank(target) then begin
 self->execute,source,_extra=extra,err=err,run=run,$
                directory_only=directory_only,/recurse
 log=self->get_log()
 return
endif

;-- save initial object state

temp=obj_struct(self)
if exist(extra) then extra=fix_extra(extra,temp)
pre_self=temp
struct_assign,self,pre_self

self->set,_extra=extra,err=err
if is_string(err) then begin
 self->log,err,_extra=extra,/error
 return
endif

if main then self->log,'Mirroring '+self.source+' => '+self.target,_extra=extra

if ~keyword_set(append) then self->set,log=''

;if run then begin
; print, String(13b), '% Running...', Format='(A,a,$)'
; print, String(13b), '', Format='(A,a,$)'
;endif

;-- process directories first


self->set,/do_directory

;if is_string(self.exclude_patt) then begin
; temp=self->strip_url(self.source)
; eignore=str_local(self.exclude_patt,/unix)
; if stregex(temp,eignore,/bool) then begin
;  self->log,'Skipping: '+self.source,_extra=extra
;  goto,skip
;endif
;endif

;-- recover last directory search state

found=0b
if run then self->restore_state,found=found,_extra=extra,err=err
   
if is_blank(err) && found then begin
 if main then self->log,['','Using results of last directory scan...'],_extra=extra 
endif else begin
 self->compare,err=err,_extra=extra
 if is_blank(err) && ~run then self->save_state,_extra=extra
endelse 

if is_string(err) then begin
 mprint,'Skipping: '+self.source
 goto,skip
endif

no_changes=self->no_changes()
if ~run && no_changes then self->log,'No directory changes.',_extra=extra,1

if run then begin
 odir=self.target
 if ~file_test(odir,/direc,/noexpand_path) then begin
  self->log,'Creating target directory - '+odir,_extra=extra
  mk_dir,odir,err=err
  if is_string(err) then begin
   self->log,log,err,_extra=extra,/error
   goto,skip
  endif
 endif
endif

if ~no_changes then begin
 if ~run then self->changes,_extra=extra
 if run then begin

;-- delete old directories

  if ~self.no_deletes && ~self.keep_directory && (self->ocount() gt 0) then self->del_dir,self->old(),_extra=extra

;-- create new directories

  if (self->ncount() gt 0) then begin
   new_dirs=concat_dir(self.target,file_basename(self->new()))
   self->mk_dir,new_dirs,_extra=extra
  endif
 
 endif
endif

if run then self->delete_state,_extra=extra

;-- compare files

if ~directory_only then begin
 self->set,do_directory=0b
  
;-- recover last file search state

 found=0b
 if run then begin
  self->restore_state,found=found,_extra=extra,err=err
 endif 
 if is_blank(err) && found then begin
  if main then self->log,'Using results of last file scan...',_extra=extra 
 endif else begin
  self->compare,err=err,_extra=extra
  if is_blank(err) && ~run then self->save_state,_extra=extra
 endelse 

 if is_string(err) then begin
  mprint,'Skipping '+self.source
  goto,skip
 endif
 
 no_changes=self->no_changes()
 if ~run && no_changes then self->log,'No file changes.',_extra=extra
 
;-- process files

 if ~no_changes then begin
 
  if ~run then self->changes,_extra=extra

  if run then begin

;-- delete old files

   if ~self.no_deletes && (self->ocount() gt 0) then self->delete,self->old(),_extra=extra

;-- copy new files

   self->copy,self->new(),_extra=extra

;-- update modified files

   self->copy,self->diff(),_extra=extra

;-- save new snapshot

   self->snap_save,_extra=extra
   self.snap_skip=0b
  endif
 endif

 if run then begin
  if ~self->snap_have() || self.snap_skip then self->snap_save,_extra=extra
  self->delete_state,_extra=extra
 endif
 
endif

;-- recurse to next directory

skip:

if recurse then begin
 ucount=self->ucount()
 if ucount gt 0 then begin
  udirs=self->ulist()
  ubdirs=file_basename(udirs)
  sdirs=self.source+'/'+ubdirs
  tdirs=concat_dir(self.target,ubdirs)
  for i=0,ucount-1 do begin 
   self->set,source=sdirs[i],target=tdirs[i],/no_check
   self->mirror,run=run,recurse=recurse,_extra=extra,$
       directory_only=directory_only,/append 
  endfor
 endif
endif

if main then begin
 if run then rmess='Mirror' else rmess='Scan'
 self->log,['',rmess+' completed at: '+!stime],_extra=extra
 etime=anytim2tai(!stime)
 self->log,'Elapsed time (secs) = '+trim2(str_format(etime-stime,'(f12.2)')),_extra=extra
 if run then begin
  if is_string(self.update_log) then begin
   status=write_ascii(self.update_log,self->get_log())  ;,/update)
   self->log,'Wrote log file to: '+self.update_log,_extra=extra
  endif
 endif else print,'% Use /run to execute actual mirror.'
endif

if arg_present(log) then log=self->get_log()

;-- restore original object state

if main then begin
 pre_self=rem_tag(pre_self,['dhash','fhash'])
 struct_assign,pre_self,self,/nozero
endif
 
return
end

;---------------------------------------------------------------
function mirror::hash,_extra=extra

if self.do_directory then return,self.dhash else return,self.fhash

end

;---------------------------------------------------------------
pro mirror::save_state,_ref_extra=extra

state={new:self->new(),old:self->old(),diff:self->diff(),ulist:self->ulist(),target:self.target,get_patt:self.get_patt,slist:self->slist(),$
       local_ignore:self.local_ignore,no_deletes:self.no_deletes,keep_directory:self.keep_directory,exclude_patt:self.exclude_patt,$
	   snap_skip:self.snap_skip}
	    
update_hash,self->hash(_extra=extra),self.target,state,_extra=extra,/no_copy

return
end

;--------------------------------------------------------------
;-- restore results of last scan

pro mirror::restore_state,found=found,_ref_extra=extra,err=err

found=0b
update_hash,self->hash(_extra=extra),self.target,state,_extra=extra,err=err,/get
if is_string(err) then begin
 self->log,err,_extra=extra,/error
 return
endif

if self->same_state(state,_extra=extra) then begin
 self->set,new=state.new,old=state.old,diff=state.diff,ulist=state.ulist,slist=state.slist
 self.snap_skip=state.snap_skip
 found=1b
endif

return
end

;---------------------------------------------------------------
;-- compare states of previous and current scans

function mirror::same_state,state,_extra=extra

if ~is_struct(state) then return,0b
same=(state.target eq self.target) && (state.no_deletes eq self.no_deletes) && $
     (state.get_patt eq self.get_patt) && (state.local_ignore eq self.local_ignore) && $
	 (state.keep_directory eq self.keep_directory) && (state.exclude_patt eq self.exclude_patt)
	 
return,same
end

;--------------------------------------------------------------
;--- clear state

pro mirror::delete_state,_ref_extra=extra

update_hash,self->hash(_extra=extra),self.target,state,_extra=extra,/del

return
end
   
;---------------------------------------------------------------
;-- get OS delim from path

function mirror::delim,path

delim='/'
if is_blank(path) then return,delim
b=byte(path)
chk1=where(b eq byte('/'),count1)
chk2=where(b eq byte('\'),count2)

if count2 gt count1 then delim='\'
return,delim
end

;----------------------------------------------------------------
;-- get time when target snapshot file was saved

function mirror::snap_time,sfile,tai=tai

if is_blank(sfile) then return,''
sobj=IDL_savefile(sfile)
scont=sobj->contents()
sdate=scont.date
a=str2arr(strcompress(sdate),delim=' ')
sdate=a[2]+'-'+a[1]+'-'+a[4]+' '+a[3]
obj_destroy,sobj
if keyword_set(tai) then sdate=anytim(sdate,/tai)
return,sdate

end

;------------------------------------------------------------
;-- return snapshot file name

function mirror::snap_name

return,'.mirror'

end
  
;---------------------------------------------------------------
;-- return snapshot file name with path

function mirror::snap_file

snap_name=self->snap_name()

return,concat_dir(self.target,snap_name)

end

;---------------------------------------------------------------
;-- get difference between create and last modification time of
;-- snapshot save file

function mirror::snap_diff,sfile,_ref_extra=extra

sdiff=0.d
if is_blank(sfile) then return,sdiff
stime=file_time(sfile,/tai)
saved_time=self->snap_time(sfile,/tai)
sdiff=(saved_time-stime)/3600.
if (sdiff ne 0.) then begin
 warn='Snapshot timestamp discrepancy (hours) = '+trim2(sdiff)
 self->log,warn,1,_extra=extra
endif

ntime=anytim2tai(!stime)
day=2.*24.d*60.*60.
if abs(ntime - stime) gt day then begin
 warn='Latest snapshot over two days old.'
; self->log,warn,1,_extra=extra
endif

return,sdiff
end

;----------------------------------------------------------------
;-- check if snapshot file exists

function mirror::snap_have,_ref_extra=extra

time=0.d
sfile=self->snap_file()
return,file_test(sfile,/reg)
 
end

;---------------------------------------------------------------
;-- check if source and directory snapshots are different

pro mirror::snap_compare,diff,_ref_extra=extra,status=status,err=err

err=''
status=0b
diff=''

source=self.source & target=self.target

;-- check for snapshot file

if ~self->snap_have() then return
sfile=self->snap_file()
sdiff=self->snap_diff(sfile,_extra=extra)
if sdiff gt 0. then begin
 self.snap_skip=1b
 return
endif

;-- compare with latest saved snapshots

restore,file=sfile

if is_blank(get_patt_sav) then get_patt_sav=''
if is_blank(local_ignore_sav) then local_ignore_sav=''
if ~isa(no_deletes_sav,/bool) then no_deletes_sav=boolean(0)

;-- if previous run used file patterns, then skip checking snapshots

;if (get_patt_sav ne self.get_patt) || $
;   (no_deletes_sav ne self.no_deletes) then begin
; self->log,'Skipping last snapshot because previous run used file pattern checking.',_extra=extra  
; self.snap_skip=1b
; return
;endif

;-- get current source snapshot

self->snap_url,source,snap_source,err=err,_extra=extra,count=scount,/cache
if is_string(err) then return

;-- get current target snapshot

self->snap_dir,target,snap_target,err=err,_extra=extra,count=tcount,/cache
if is_string(err) then return

;-- compare snapshots

same_source=array_equal(snap_source,snap_source_sav)
same_target=array_equal(snap_target,snap_target_sav)

;-- find files changed on source

dsfiles=''
if ~same_source then begin
 dsource=str_difference(snap_source,snap_source_sav,count=dscount)
 if dscount gt 0 then begin
  dsfiles=stregex(dsource,'\"\>([^\>]+)\<\/a\>',/sub,/extract)
  dsfiles=reform(dsfiles[1,*],/over)
 endif
endif

;-- find files changed on target

dtfiles=''
if ~same_target then begin
 dtarget=str_difference(snap_target,snap_target_sav,count=dtcount)
 tignore=str_local(self.local_ignore)
 if dtcount gt 0 then begin  
  tlist=strsplit(dtarget,' ',/extract)  
  for i=0,dtcount-1 do begin    
   if dtcount eq 1 then tarr=tlist else tarr=tlist[i]
   tsize=n_elements(tarr)
   tname=tarr[tsize-1]
   if tname eq '' then continue
   if is_string(tignore) then if stregex(tname,tignore,/bool) then continue
   tfile=concat_dir(target,tname)
   if tname eq self->snap_name() then continue
   if ~file_test(tfile,/reg) then continue
   if dtfiles[0] eq '' then dtfiles=tname else dtfiles=[temporary(dtfiles),tname]
  endfor 
 endif
endif

ncount=self->ncount()
ocount=self->ocount()
tfiles=[temporary(dsfiles),temporary(dtfiles)]
dfiles=rem_blanks(get_uniq(tfiles),count=dcount)

if (dcount gt 0) && (ncount gt 0) then dfiles=str_remove(dfiles,file_basename(self->new()),count=dcount)
if (dcount gt 0) && (ocount gt 0) then dfiles=str_remove(dfiles,file_basename(self->old()),count=dcount)

if dcount gt 0 then begin
 if dcount eq 1 then dfiles=dfiles[0]
 diff=source+'/'+dfiles
 self->log,'Source and target have different snapshots.',_extra=extra
endif

status=1b
return
end

;------------------------------------------------------------
;-- list directories in directory (excluding link directories)

pro mirror::list_dirs,dir,dirs,count=count,cache=cache,_ref_extra=extra

count=0L
dirs=''

if ~self->is_dir(dir,_extra=extra) then return
have_dirs=0b
if keyword_set(cache) then begin
 dir_cache=self.dir_cache
 have_dirs=dir_cache->haskey(dir)
 if have_dirs then begin
  dirs=dir_cache[dir]
  count=dir_cache['count']
  mprint,'Restoring from DIR_CACHE - '+dir
  return
 endif  
endif

if ~have_dirs then begin
 path=concat_dir(dir,'*')
 lcount=0l
 dirs=file_search(path,count=count,/test_directory,/match_initial_dot,/nosort)
 windows=is_windows()
 if ~windows && (count gt 0) then begin
  lout=file_search(path,count=lcount,/test_directory,/match_initial_dot,/nosort,/test_sym)
  if (lcount gt 0) then begin
   for i=0,lcount-1 do self->log,'Ignoring target link directory: '+lout[i],_extra=extra
   no_link=rem_elem(out,lout,count)
   if count gt 0 then dirs=dirs[no_link] else dirs=''
  endif
 endif
endif

if count eq 1 then dirs=dirs[0]
;mprint,'Saving to DIR_CACHE - '+dir
dir_cache=self.dir_cache
dir_cache[dir]=dirs
dir_cache['count']=count

return & end

;------------------------------------------------------------

function mirror::is_dir,dir,err=err,_ref_extra=extra
err=''
ok=0b

case 1 of
 n_elements(dir) gt 1: err='Input directory must be a scalar.'
 is_blank(dir): err='Input directory must be a non-blank string.'
 ~is_dir(dir): err='Input directory does not exist - '+dir
 else: ok=1b
endcase

if ~ok then self->log,err,/error,_extra=extra

return,ok
end

;-------------------------------------------------------------
;-- list files in directory (excluding snapshots)

pro mirror::list_files,dir,files,count=count,cache=cache,_ref_extra=extra
count=0L 
files=''
if ~self->is_dir(dir,_extra=extra) then return

have_files=0b
if keyword_set(cache) then begin
 file_cache=self.file_cache
 have_files=file_cache->haskey(dir)
 if have_files then begin
  files=file_cache[dir]
  count=file_cache['count']
  mprint,'Restoring from FILE_CACHE - '+dir
  return
 endif
endif

if ~have_files then begin
 path=concat_dir(dir,'*')
 files=file_search(path,count=count,/test_reg,/match_initial_dot,/nosort) 
 if count gt 0 then begin
  snap_file=self->snap_file()
  chk=where(snap_file ne files,count)
  if count gt 0 then begin
   if count lt n_elements(files) then files=files[chk]
  endif else files=''
 endif
endif

if count eq 1 then files=files[0]
;mprint,'Saving to FILE_CACHE - '+dir
file_cache=self.file_cache
file_cache[dir]=files
file_cache['count']=count

return & end

;-------------------------------------------------------------
;-- get snapshot of URL

pro mirror::snap_url,url,listing,_ref_extra=extra,err=err

err=''
listing=''
slist=self->slist()
if is_string(slist) then begin
 if slist[0] eq 'No data' then begin
  err='No data'
  return
 endif
 listing=slist
 return
endif

;self->search_url,url,out,listing=listing,_extra=extra,/no_check

return & end

;-----------------------------------------------------------
;-- get snapshot of directory

pro mirror::snap_dir,dir,listing,_ref_extra=extra,err=err

err=''
ndir=local_name(dir)
if is_windows() then begin
 spawn,'dir '+ndir,listing,err_result,/hide
endif else begin
 cmd=['ls','-al',ndir]
 spawn,cmd,listing,err_result,/noshell,_extra=extra
endelse

err=strjoin(err_result,', ')
listing=strcompress(listing)

return & end

;---------------------------------------------------------------
pro mirror::snap_save,err=err,_ref_extra=extra

err=''
error=0
catch,error
if (error ne 0) then begin
 err=err_state()
 catch, /cancel
 message,/reset
 self->log,err,_extra=extra,/error
 return
endif

source=self.source & target=self.target
if is_blank(source) || is_blank(target) then return

;-- update latest source and target snapshots

sfile=self->snap_file()
file_delete,sfile,/allow_nonex,/quiet
self->snap_url,source,snap_source_sav,err=err,_extra=extra,/cache
if is_string(err) then return

self->snap_dir,target,snap_target_sav,err=err,_extra=extra
if is_string(err) then return

get_patt_sav=self.get_patt
local_ignore_sav=self.local_ignore
no_deletes_sav=self.no_deletes

self->log,'Saving new snapshot to: '+sfile,_extra=extra,1
save,file=sfile,snap_source_sav,snap_target_sav,get_patt_sav,local_ignore_sav,no_deletes_sav

return & end
;----------------------------------------------------------------
;-- delete old directories

pro mirror::del_dir,dir,_ref_extra=extra

chk=where(dir ne '',ocount)
if (ocount eq 0) then return
windows=is_windows()
for i=0,ocount-1 do begin
 old=local_name(dir[chk[i]])
 err=''
 if windows then check=0b else check=file_test(old,/dir,/sym)
 if check then begin
  self->log,'Not deleting symbolic link directory: '+old,_extra=extra
  continue 
 endif
 if ~file_test(old,/direc,/noexpand_path) then begin
  err='Missing directory: '+old
  self->log,err,_extra=extra,/error
  continue
 endif 
 file_delete2,old,/recursive,/noexpand_path,err=err,/quiet
 if is_string(err) then begin
  err='Unable to delete directory: '+old
  self->log,err,_extra=extra,/error
 endif else self->log,'Deleting directory: '+old,_extra=extra
endfor

return & end

;---------------------------------------------------------------------------------
;-- create new directories

pro mirror::mk_dir,dir,_ref_extra=extra

chk=where(dir ne '',ncount)
if (ncount eq 0) then return
odir=local_name(self.target)

;-- verify write access to target

if ~file_test(odir,/write,/noexpand_path) then begin
 err='Denied write access to directory: '+odir
 self->log,err,_extra=extra,/error
 return
endif

for i=0,ncount-1 do begin
 new=local_name(dir[chk[i]])
 err=''
 self->log,'Creating directory: '+new,_extra=extra
 mk_dir,new,err=err,/noexpand_path
 if is_string(err) then self->log,err,_extra=extra,/error
endfor

return & end

;--------------------------------------------------------------------
;-- delete defunct files

pro mirror::delete,file,_ref_extra=extra
 
chk=where(file ne '',ocount)
if (ocount eq 0) then return
for i=0,ocount-1 do begin
 old=file[chk[i]]
 if ~file_test(old,/regular,/noexpand_path) then begin
  err='Missing file: '+old
  self->log,err,_extra=extra,/error
  continue
 endif
 file_delete2,old,/noexpand_path,err=err,/quiet  
 if is_blank(err) then self->log,'Deleting file: '+old,_extra=extra else begin
  err='Unable to delete file: '+old
  self->log,err,_extra=extra,/error
 endelse
endfor
 
return
end

;--------------------------------------------------------------------
;-- compare files/directories on source and target

; Keywords:     
; OLD = files/directories in target that are not on source
; NEW = files/directories on source that are not on target
; DIFF = files on target that differ from source (in size & time)
; ULIST = updated list of files/directories on target after removing OLD and adding NEW

pro mirror::compare,_ref_extra=extra,err=err

err=''

;-- search files/directories

self->search,_extra=extra,err=err
;if is_string(err) then begin
; self->log,err,_extra=extra,/warn
;endif

;-- filter selected/excluded/ignored directories/files

self->filter,_extra=extra,err=err
if is_string(err) then begin 
 self->log,err,_extra=extra,/error
 return
endif

;-- find differences

self->difference,_extra=extra,err=err
if is_string(err) then self->log,err,_extra=extra,/error

return & end

;---------------------------------------------------------------------------
;-- search for file/directories on source and target

pro mirror::search,_ref_extra=extra,err=err
err=''

if is_blank(self.target) then begin
 err='Missing target site.'
 return
endif

if is_blank(self.source) then begin
 err='Missing source site.'
 return
endif

self->set,tdirs='',tfiles='',sdirs='',sfiles=''

;-- skip target directory if ignoring

if is_string(self.local_ignore) then begin
 tignore=str_local(self.local_ignore)
 if stregex(self.target,tignore,/bool) then begin
  if ~self.do_directory then begin
   self->log,'Ignoring: '+self.target,_extra=extra
   return
  endif
 endif
endif

if ~self.do_directory then item='files' else item='directories'

self->log,['','Scanning '+item+' in: '+self.target],_extra=extra,self.do_directory

self->search_url,self.source,out,_extra=extra,err=err,count=count
if is_string(err) then return
if count gt 0 then if self.do_directory then self->set,sdirs=out else self->set,sfiles=out

self->search_dir,self.target,out,_extra=extra,err=err,count=count
if is_string(err) then return
if count gt 0 then if self.do_directory then self->set,tdirs=out else self->set,tfiles=out

return & end

;--------------------------------------------------------------------
;-- check if variable is a URL

function mirror::is_url,var

if is_blank(var) || (n_elements(var) ne 1) then return,0b

return,stregex(var,'^http',/bool)

end

;---------------------------------------------------------------------
;-- search directory

pro mirror::search_dir,dir,out,count=count,_ref_extra=extra

count=0l
out=''

if ~self->is_dir(dir,_extra=extra) then return

;if ~file_test(dir,/read,/noexpand_path) then begin
; chmod,dir,/noexpand_path,/u_read
; if ~file_test(dir,/read,/noexpand_path) then self->log,'Warning - denied read access to: '+dir,_extra=extra
;endif

if self.do_directory then $
 self->list_dirs,dir,out,count=count,_extra=extra else $
  self->list_files,dir,out,count=count,_extra=extra

return & end

;--------------------------------------------------------------------
;-- search URL

pro mirror::search_url,url,out,count=count,_ref_extra=extra,err=err,listing=listing
err='' & count=0l & out=''

sock_search,url,out,_extra=extra,err=err,count=count,/no_check,$
 directory=self.do_directory,cache=~self.do_directory,listing=listing

if ~self.do_directory then begin
 if is_string(err) then self->log,err,_extra=extra,/error
 self->set,slist=listing 
endif

if count eq 0 then out=''

return & end

;-----------------------------------------------------------------------------------
;-- filter directories & files

pro mirror::filter,_ref_extra=extra,err=err,skip_directories=skip_directories,ignore_files=ignore_files

err=''
direct=self.do_directory
windows=is_windows()

;-- select requested patterns

if is_string(self.get_patt) then begin
 
 if direct then item='directories' else item='files'
 scount=self->scount()
 if scount gt 0 then begin
  get_patt=str_local(self.get_patt,/unix)
  stemp=self->source()
  if direct then snames=self->strip_url(stemp) else snames=file_basename(stemp)
  index=where(stregex(snames,get_patt,/bool),pcount)
  if (pcount gt 0) then begin
   if (pcount lt scount) then stemp=stemp[index]
  endif else begin
   self->log,'No source '+item+' matching: '+get_patt,_extra=extra
   stemp=''
  endelse
  if direct then begin
   if (pcount gt 0) then self->set,sdirs=stemp
  endif else self->set,sfiles=stemp
  if pcount ne 0 then begin
   self->log,'Following source '+item+' will be mirrored: ',_extra=extra
   self->log,stemp,_extra=extra
  endif
 endif
 
 tcount=self->tcount()
 if tcount gt 0 then begin
  get_patt=str_local(self.get_patt)
  ttemp=self->target()
  if direct then tnames=ttemp else tnames=file_basename(ttemp)
  reject=str_remove(tnames,get_patt,/regex,rcount=rcount,rindex=rindex)
  if (rcount gt 0) then begin
   if (rcount lt tcount) then ttemp=ttemp[rindex]
  endif else begin
   ttemp=''
  endelse
  if direct then begin
   if (rcount gt 0) then self->set,tdirs=ttemp 
  endif else self->set,tfiles=ttemp
 endif  

endif

;-- ignore target directory/file patterns

if is_string(self.local_ignore) then begin
 scount=self->scount()
 if (scount gt 0) then begin
  signore=str_local(self.local_ignore,/unix)
  stemp=self->source()
  if direct then snames=self->strip_url(stemp) else snames=self->basename(self.source,stemp)
  out=str_remove(snames,signore,_extra=extra,/regex,index=index,count=count)
  if count gt 0 then begin
   if count lt self->scount() then stemp=stemp[index]
  endif else stemp=''
  if direct then self->set,sdirs=stemp else self->set,sfiles=stemp
 endif

 tcount=self->tcount()
 if (tcount gt 0) then begin
  ttemp=self->target()
  tignore=str_local(self.local_ignore)
  if direct then tnames=ttemp else tnames=self->basename(self.target,ttemp)
  out=str_remove(tnames,tignore,_extra=extra,rcount=rcount,rindex=rindex,/regex,$
                 count=count,index=index)
  if direct then item='directories' else item='files'
  if rcount gt 0 then begin
   self->log,'Following '+item+' will be ignored: ',_extra=extra
   self->log,ttemp[rindex],_extra=extra
  endif

  if count gt 0 then begin
   if count lt self->tcount() then ttemp=ttemp[index]
  endif else ttemp=''
  if direct then self->set,tdirs=ttemp else self->set,tfiles=ttemp
 endif
endif

;-- remove excluded patterns (legacy PERL/Mirror)

new_mirror=is_string(skip_directories) || is_string(ignore_files)

if is_string(self.exclude_patt) && ~new_mirror then begin
 skip_directories=self.exclude_patt
 ignore_files=self.exclude_patt
endif

if direct then begin
 if is_string(skip_directories) && (self->scount() gt 0) then begin
  excl=str_local(skip_directories,/unix)
  sdirs=self->source()
  snames=self->strip_url(sdirs)
  out=str_remove(snames,excl,_extra=extra,/regex,count=count,index=index)
  if count gt 0 then begin
   if count le self->scount() then sdirs=sdirs[index]
  endif else sdirs=''
  self->set,sdirs=sdirs
 endif
endif

;-- remove excluded files

if ~direct then begin
 if is_string(ignore_files) && (self->scount() gt 0) then begin
  excl=str_local(ignore_files,/unix)
  sfiles=self->source()
  snames=self->basename(self.source,sfiles)
  out=str_remove(snames,excl,_extra=extra,/regex,count=count,index=index)
  if count gt 0 then begin
   if count le self->scount() then sfiles=sfiles[index]
  endif else sfiles=''
  self->set,sfiles=sfiles
 endif
endif

return & end

;--------------------------------------------------------------
function mirror::strip_url,names

if ~isa(names,/string) then return,''
if ~self->is_url(self.source) || is_blank(self.url) then return,names
len=strlen(self.url)
slens=max(strlen(names))
snames=strmid(names,len,slens)
return,snames
end

;---------------------------------------------------------------
function mirror::basename,dir,names

if ~isa(names,/string) then return,''
if is_blank(dir) then return,names
len=strlen(dir)
slens=max(strlen(names))
snames=strmid(names,len+1,slens)
return,snames
end

;--------------------------------------------------------------
function mirror::old

return,*self.old
end

;--------------------------------------------------------------
function mirror::new

return,*self.new
end

;--------------------------------------------------------------
function mirror::diff

return,*self.diff
end

;--------------------------------------------------------------
function mirror::ulist

return,*self.ulist
end

;--------------------------------------------------------------
function mirror::slist

return,*self.slist
end

;---------------------------------------------------------------
function mirror::tfiles

return,*self.tfiles
end
;---------------------------------------------------------------

function mirror::sfiles
 
return,*self.sfiles
end

;---------------------------------------------------------------
function mirror::tdirs

return,*self.tdirs
end

;---------------------------------------------------------------
function mirror::sdirs
 
return,*self.sdirs
end

;-----------------------------------------------------------------
;-- number of search results on source

function mirror::scount

if self.do_directory then ref=self->sdirs() else ref=self->sfiles()
chk=where(ref ne '',count)
return,count

end

;-----------------------------------------------------------------
; number of search results on target

function mirror::tcount

if self.do_directory then ref=self->tdirs() else ref=self->tfiles()
chk=where(ref ne '',count)
return,count

end

;-------------------------------------------------------------------
;-- return source search results

function mirror::source

if self.do_directory then return,self->sdirs() else return,self->sfiles()
end

;-------------------------------------------------------------------
;-- return target search results

function mirror::target

if self.do_directory then return,self->tdirs() else return,self->tfiles()
end

;--------------------------------------------------------------------
function mirror::ncount

chk=where(self->new() ne '',ncount)
return,ncount
end

;-------------------------------------------------------------------
function mirror::ocount

chk=where(self->old() ne '',ocount)
return,ocount
end

;------------------------------------------------------------------
function mirror::dcount

chk=where(self->diff() ne '',dcount)
return,dcount
end

;------------------------------------------------------------------
function mirror::ucount

chk=where(self->ulist() ne '',ucount)
return,ucount
end

;--------------------------------------------------------------------
;-- find differences between source and target 

pro mirror::difference,_ref_extra=extra,err=err

err=''
diff=''
self->set,old='',new='',diff=diff


scount=self->scount()
if scount gt 0 then begin
 sout=self->source()
 sbout=self->basename(self.source,sout)
endif

tcount=self->tcount()
if tcount gt 0 then begin
 tout=self->target()
 tbout=self->basename(self.target,tout)
endif

;-- look for new/defunct directories

if self.do_directory then begin
 ulist=''
 self->set,ulist=ulist
 
 case 1 of
  (tcount eq 0) && (scount eq 0): do_nothing=1
  (tcount eq 0) && (scount gt 0): self->set,new=sout
  (tcount gt 0) && (scount eq 0): self->set,old=tout
  else: begin
   oindex=rem_elem(tbout,sbout,ocount)
   if ocount gt 0 then self->set,old=tout[oindex]
   nindex=rem_elem(sbout,tbout,ncount)
   if ncount gt 0 then self->set,new=sout[nindex]
  end
 endcase
 
 if tcount gt 0 then begin
  ulist=tout
  ocount=self->ocount()
  if (ocount gt 0) then ulist=str_remove(tout,self->old())
 endif

 ncount=self->ncount()
 if (ncount gt 0) then ulist=[ulist,concat_dir(self.target,file_basename(self->new()))]
 chk=where(ulist ne '',ucount)
 if ucount gt 0 then begin
  if ucount lt n_elements(ulist) then ulist=ulist[chk]
  if ucount eq 1 then ulist=ulist[0]
 endif
 
 self->set,ulist=ulist
endif

;-- look for new/defunct/modified files

if ~self.do_directory then begin
 self.snap_skip=0b
 case 1 of
  (tcount eq 0) && (scount eq 0): do_nothing=1
  (tcount eq 0) && (scount gt 0): self->set,new=sout
  (tcount gt 0) && (scount eq 0): self->set,old=tout
  else: begin
   oindex=rem_elem(tbout,sbout,ocount)
   if ocount gt 0 then self->set,old=tout[oindex]
   nindex=rem_elem(sbout,tbout,ncount)
   if ncount gt 0 then self->set,new=sout[nindex]
  
 ;-- if forcing an update, then no need to check for file differences      

   if self.force then begin
    if scount gt 0 then begin
	 diff=sout
	 if (ncount gt 0)then diff=str_remove(sout,self->new())
	endif
	self->log,'Forcing update from: '+self.source,_extra=extra 
	self->set,diff=diff
	return
   endif
    
;-- only check files that have changed in saved snapshots

   if ~self.no_cache && self->snap_have() then begin
    stime=file_time(self->snap_file())
    self->log,'Checking last snapshot taken at '+stime+' found in: '+self.target,_extra=extra,1
    self->snap_compare,diff,_extra=extra,status=status,err=err
    if is_string(err) then return  
    if status then begin
     self->set,diff=diff
     return
    endif
   endif
    
;-- check all source/target file for differences
      
   self->log,'Checking times/sizes of files in: '+self.target,_extra=extra
   for i=0l,scount-1 do begin
    self->log,'Checking: '+sbout[i]+'...',1,_extra=extra
    chk=where(sbout[i] eq tbout,ccount)
    k=chk[0]
    if ccount eq 0 then continue
    ssize=self->file(sout[i],time=stime,err=err,_extra=extra)
	if is_string(err) then continue
	tsize=self->file(tout[k],time=ttime,_extra=extra)
	ssame=(tsize eq ssize)
    tsame=0b
    if ssame then begin
     tdiff=abs((ttime-stime))
     tsame=((tdiff mod 3600.) eq 0.) && (tdiff lt 12.*3600.)
	 ;tsame=(tdiff eq 0.)
    endif
    if ~ssame || ~tsame then begin
      ; tdiff=trim2((ttime-stime)/3600.)
      ; sdiff=trim2(tsize-ssize)
      ; self->log,sbout[i]+'- TDIFF (hours) = '+tdiff,_extra=extra,1
     if diff[0] eq '' then diff=sout[i] else diff=[temporary(diff),sout[i]]
    endif
   endfor
   self->set,diff=diff
  end
 endcase

endif
 
return & end

;------------------------------------------------------------------------

function mirror::no_changes

ncount=self->ncount()
ocount=self->ocount()
dcount=self->dcount()

return,(ncount eq 0) && (ocount eq 0) && (dcount eq 0)
end

;-------------------------------------------------------------------------
;-- output summary of changes

pro mirror::changes,_ref_extra=extra

ncount=self->ncount()
ocount=self->ocount()
dcount=self->dcount()
type=self->type()

if (ncount eq 0) && (ocount eq 0) && (dcount eq 0) then begin
 self->log,'No '+type+' changes in: '+self.target,_extra=extra,1
 return
endif

if ocount gt 0 then begin
 old=self->old()
 if self.do_directory then pecho=~self.keep_directory && ~self.no_deletes else pecho=~self.no_deletes
 if pecho then for i=0,ocount-1 do self->log,'Non-matching target '+type+': '+old[i],_extra=extra
endif

if ncount gt 0 then begin
 new=self->new()
 item=concat_dir(self.target,file_basename(new))
 if self->type() eq 'directory' then new=item
 for i=0,ncount-1 do self->log,'New '+type+': '+item[i],_extra=extra
endif

dcount=self->dcount()
if dcount gt 0 then begin
 diff=self->diff()
 if type eq 'file' then item=concat_dir(self.target,file_basename(diff)) else item=diff
 if ~self.force then begin
  for i=0,dcount-1 do self->log,'Modified '+type+': '+item[i],_extra=extra
 endif
endif

return & end

;--------------------------------------------------------------------------
;-- get file size and time attributes 

function mirror::file,file,err=err,time=time,_ref_extra=extra

err=''
time=0d
if is_blank(file) then return,0L

;-- file is remote URL

if self->is_url(file) then begin
 rfile=self->encode(file)
 rsize=sock_size(rfile,date=rdate,err=err,_extra=extra)
 if is_blank(err) && is_blank(rdate) then err='Missing timestamp - '+rfile 
 if is_string(err) then begin
  self->log,err,_extra=extra,/error
  time=0d & rsize=0L
 endif else time=anytim(rdate) 
 return,rsize
endif

;-- else it's a regular file

stc=file_info(file)
lsize=long(stc.size)
mtime=stc.mtime
ldate=systim(0,mtime)
time=anytim(ldate)

return,lsize
end

;-----------------------------------------------------------------------------------
;-- encode special characters

function mirror::encode,file

if is_blank(file) then return,''
bname=file_basename(file)
ename=ascii_encode(bname)
efile=file
if ename ne bname then efile=str_replace(file,bname,ename)
return,efile
end

;--------------------------------------------------------------------------
;-- copy or download file (if URL)

pro  mirror::copy,file,err=err,_ref_extra=extra

err=''
chk=where(file ne '',count) 
if count eq 0 then return

;-- verify write access to target directory

odir=self.target
if ~file_test(odir,/write,/noexpand_path) then begin
 err='Denied write access to directory: '+odir
 self->log,err,_extra=extra,/error
 return
endif

for i=0,count-1 do begin
 sfile=file[chk[i]]
 item=concat_dir(odir,file_basename(sfile))
 current=file_test(item,/regular,/noexpand_path)
 mode='Updating: '
 if ~current then mode='Copying: '
 if self->is_url(sfile) then if ~current then mode='Downloading: '
 self->log,mode+item,_extra=extra

;-- verify write access to file

 if current then begin
  if ~file_test(item,/write,/noexpand_path) then begin
   err='Denied write access to file: '+item
   self->log,err,_extra=extra,/error
   continue
  endif
 endif
 
;-- catch unanticipated errors

 error=0
 catch,error
 if (error ne 0) then begin
  err=err_state()
  catch, /cancel
  message,/reset
  self->log,err,_extra=extra,/error
  continue
 endif

 if self->is_url(sfile) then begin
  rfile=self->encode(sfile)
  sock_get,rfile,out=odir,local=local,/clobber,/no_check,/quiet,err=err,_extra=extra,/no_dir_check
  if is_blank(err) then begin
   alocal=ascii_decode(local)
   if alocal ne local then file_rename,local,alocal,err=err,_extra=extra
  endif
 endif else begin
  file_copy,sfile,odir,/force,/overwrite,/allow_same,/noexpand_path
  file_touch,item,sfile,err=err
  chmod,item,/u_read,/u_write,/g_read,/g_write,/a_execute
 endelse

 if is_string(err) then self->log,err,_extra=extra,/error

endfor

return
end

;----------------------------------------------------------------------
;-- set properties

pro mirror::set,target=target,source=source,do_directory=do_directory,$
                tdirs=tdirs,sdirs=sdirs,tfiles=tfiles,sfiles=sfiles,log=log,$
                err=err,no_check=no_check,local_ignore=local_ignore,$
                get_patt=get_patt,no_deletes=no_deletes,force=force,no_cache=no_cache,$
                keep_directory=keep_directory,update_log=update_log,$
                exclude_patt=exclude_patt,new=new,old=old,diff=diff,ulist=ulist,slist=slist
          
err=''
if isa(source,/string) then begin
 if is_blank(source) then begin
  err='Source cannot be blank.'
  mprint,err
  return
 endif
 if self->is_url(source) then begin
  source=str_replace(source,'\','/')
  if keyword_set(no_check) then self.source=source else begin
   sock_redirect,source,location,err=err,/verbose,/full_path
   if is_string(err) then return
   if is_string(location) then self.source=location else self.source=source
   url=url_parse(self.source)
   self.url=url.scheme+'://'+url.host
  endelse
 endif else begin
  err='Source must be a valid URL.'
  mprint,err
  return
 endelse
endif

if isa(target,/string) then begin
 if is_blank(target) then begin
  err='Target cannot be blank.'
  mprint,err
  return
 endif
 if self->is_url(target) then begin
  err='Target cannot be a URL.'
  mprint,err
  return
 endif
 self.target=local_name(target)
endif

if is_number(do_directory) then self.do_directory=do_directory
if isa(tfiles,/string) then *self.tfiles=tfiles
if isa(sfiles,/string) then *self.sfiles=sfiles
if isa(tdirs,/string) then *self.tdirs=tdirs
if isa(sdirs,/string) then *self.sdirs=sdirs
if isa(new,/string) then *self.new=new
if isa(old,/string) then *self.old=old
if isa(diff,/string) then *self.diff=diff
if isa(ulist,/string) then *self.ulist=ulist
if isa(slist,/string) then *self.slist=slist

if is_string(log,/blank) then *self.log=log
if is_string(local_ignore,/blank) then self.local_ignore=local_ignore
if is_string(get_patt,/blank) then self.get_patt=get_patt
if is_string(exclude_patt,/blank) then self.exclude_patt=exclude_patt

if is_number(no_deletes) then self.no_deletes=no_deletes 
if is_number(force) then self.force=force 
if is_number(no_cache) then self.no_cache=no_cache 
if is_number(keep_directory) then self.keep_directory=keep_directory 

if is_string(update_log,/blank) then begin
 if is_blank(update_log) then self.update_log='' else begin
  odir=file_dirname(update_log)
  if (is_blank(odir) || odir eq '.') then odir=curdir()
  if ~file_test(odir,/directory) then begin
   err='Output directory for log file does not exist: '+odir
   self.update_log=''
   return
  endif
  if ~file_test(odir,/directory,/write) then begin
   err='Output directory for log file does not have write access: '+odir
   self.update_log=''
   return
  endif
  self.update_log=concat_dir(odir,file_basename(update_log))
 endelse
endif
return
end

;----------------------------------------------------------------------------
;-- update results log

pro mirror::log,input,level,_ref_extra=extra,verbose=verbose,error=error,$
                             previous=previous

if keyword_set(error) then begin
 caller=get_caller(prev_caller=prev_caller)
 if keyword_set(previous) then ocaller=prev_caller else ocaller=caller
 output=ocaller+': '+input
 overbose=1b
endif else begin
 output=input
 overbose=keyword_set(verbose)
endelse

str_log,*self.log,output,level,_extra=extra,verbose=overbose

return & end

;-----------------------------------------------------------------------------
;-- get results log

function mirror::get_log

return,*(self.log)

end

;-------------------------------------------------------------------
;-- reset properties

pro mirror::reset

*self.sfiles=''
*self.tfiles=''
*self.sdirs=''
*self.tdirs=''
*self.diff=''
*self.new=''
*self.old=''
*self.slist=''
*self.ulist=''

return & end

;--------------------------------------------------------------------
;-- return search type

function mirror::type,plural=plural

if keyword_set(plural) then begin
 if self.do_directory then return,'directories' else return,'files'
endif

if self.do_directory then return,'directory' else return,'file'

end
;--------------------------------------------------------------------
;-- read mirror package file

pro mirror::read,file,ndata,_ref_extra=extra,err=err,count=count

count=0
ndata=''
err=''
if is_blank(file) then begin
 err='Blank or invalid package file name.'
 return
endif

if ~file_test(file,/reg) then begin
 err='Package file not found: '+file
 return
endif

delvarx,ndata,buff
data=rd_tfile(file)
data=strtrim(data,2)
chk=stregex(data,'^package',/bool,/fold)
packages=where(chk,count)
if count eq 0 then begin
 err='No packages in file: '+file
 return
endif

nd=n_elements(data)
for i=0,count-1 do begin
 p1=packages[i]
 if (i+1) lt count then p2=packages[i+1]-1 else p2=nd-1 
 buff=data[p1:p2]
 chk=where(strpos(buff,'#') ne 0,hcount)
 if (hcount gt 0) && (hcount lt n_elements(buff)) then buff=buff[chk] 
 boost_array,ndata,buff
endfor

return
end

;----------------------------------------------------------------------------
;-- extract keywords from package file data

function mirror::parse,pdata,tag,_ref_extra=extra

value=''
if is_blank(pdata) then return,''
if is_blank(tag) then return,''

regex=' *'+strtrim(tag,2)+' *= *(.+)'
out=stregex(pdata,regex,/ext,/sub,_extra=extra)

out=strtrim(out,2)
chk=where(out[1,*] ne '',count)
if count gt 0 then begin
 value=out[1,chk[count-1]]
endif

return,value

end

;----------------------------------------------------------------
;-- run mirror in a thread

pro mirror::thread,package,_ref_extra=extra

thread,'self->mirror',package,_extra=extra

return
end

;-----------------------------------------------------------------
;-- run mirror from package file

pro mirror::execute,package,_extra=extra,err=err

err=''
self->read,package,ndata,err=err,count=count
if is_string(err) then begin
 self->log,err,_extra=extra,/error
 return
endif

for i=0,count-1 do begin
 self->set,log=''
 pdata=ndata[*,i]
 site=self->parse(pdata,'site')
 remote_dir=self->parse(pdata,'remote_dir')
 local_dir=local_name(self->parse(pdata,'local_dir'))
 package=self->parse(pdata,'package')
 comment=self->parse(pdata,'comment')

;-- determine source and target

 if is_blank(site) || is_blank(remote_dir) || is_blank(local_dir) then begin
  err='Skipping invalid package: '+package
  self->log,err,_extra=extra,/error
  continue
 endif

 if is_string(package) then begin
  lab='Processing package: '+package
  slab=strlen(lab)
  plab=strpad('-',slab,fill='-')
  self->log,[' ',lab,plab],_extra=extra
 endif
 ;self->log,site+remote_dir+' => '+local_dir,_extra=extra
 ;if is_string(comment) then self->log,comment,_extra=extra
 
 if ~self->is_url(site) then site='https://'+site
 source=site+remote_dir
 target=local_dir

;-- force local deletes

 do_deletes=strlowcase(self->parse(pdata,'do_deletes'))
 no_deletes=(do_deletes eq 'false') || (do_deletes eq 'no')

;-- force updates

 force=strlowcase(self->parse(pdata,'force'))
 force=(force eq 'true') || (force eq 'yes')
 exclude_patt=self->parse(pdata,'exclude_patt')

;-- override package keywords with command keywords
;   (+keyword will append command keyword to package keyword)

ready=0b
if ready then begin 
 plus=0b & k_exclude_patt=''
 if is_string(exclude_patt) then begin
  val=exclude_patt
  len=strlen(val)
  plus=strpos(val,'+') eq 0
  if plus then val=strmid(val,1,len-1)
  k_exclude_patt=val
 endif  
 
 p_exclude_patt=self->parse(pdata,'exclude_patt')
; if is_string(p_exclude_patt) then begin
;  val=p_exclude_patt
;  val=str_rep(val,'(','')
;  val=str_rep(val,')','')
;  p_exclude_patt=val
; endif
 
 case 1 of
  is_string(k_exclude_patt) && is_blank(p_exclude_patt): c_exclude_patt=k_exclude_patt
  is_string(p_exclude_patt) && is_blank(k_exclude_patt): c_exclude_patt=p_exclude_patt
  is_string(p_exclude_patt) && is_string(k_exclude_patt): begin
   if plus then begin
    pval=strsplit(p_exclude_patt,'|',/extrac)
    kval=strsplit(k_exclude_patt,'|',/extrac)
    cval=get_uniq([pval,kval])
    c_exclude_patt=strjoin(cval,'|')
   endif else c_exclude_patt=k_exclude_patt
  end
  else:c_exclude_patt=''
 endcase
endif

 get_patt=self->parse(pdata,'get_patt')
 local_ignore=self->parse(pdata,'local_ignore')
 update_log=self->parse(pdata,'update_log')
 self->set,source=source,target=target,err=err
 if is_string(err) then begin
  self->log,err,_extra=extra,/error
  continue
 endif

 self->mirror,_extra=extra,no_deletes=no_deletes,force=force,update_log=update_log,$
  exclude_patt=exclude_patt,/append,get_patt=get_patt,$
  local_ignore=local_ignore

endfor

return & end

;--------------------------------------------------------------------------
pro mirror::cleanup

ptr_free,self.tdirs,self.sdirs,self.sfiles,self.tfiles,self.log,$
 self.new,self.old,self.diff,self.ulist,self.slist
obj_destroy,self.file_cache
obj_destroy,self.dir_cache
obj_destroy,self.dhash
obj_destroy,self.fhash
         
return
end

;------------------------------------------------------------------
pro mirror::help

a="||Example uses:||;-- create map object instance||IDL> m=mirror()                ||;-- mirror SSW gen tree to user directory||;-- first define source and target directories||IDL> source='https://sohowww.nascom.nasa.gov/solarsoft/gen/idl'|IDL> target='~/solarsoft/gen/idl||;-- load them into mirror object||IDL> m->set,source=source,target=target||;-- compare top-level directories and files||IDL> m->mirror,/verb        ||;-- compare top- and sub-level directories and files recursively||IDL> m->mirror,/recurse,/verb||;-- run/execute mirror||IDL> m->mirror,/recurse,/run,/verb|"

b=strsplit(a,'|',/extrac,/preserve)

print,transpose(b)

return & end

;------------------------------------------------------------------

pro mirror__define                                                                                   
                                                                                                  
void={mirror, $                                                                                       
     source:'',$              ;-- source directory or URL to mirror from                                                                          
     target:'',$              ;-- target directory to mirror to
     do_directory:boolean(0),$
     tdirs:ptr_new(), $
     sdirs:ptr_new(), $
     sfiles:ptr_new(),$
     tfiles:ptr_new(),$
     new:ptr_new(),$
     old:ptr_new(),$
     diff:ptr_new(),$ 
	 ulist:ptr_new(),$
     log:ptr_new(),$
     local_ignore:'',$
     get_patt:'',$
     exclude_patt:'',$
     no_deletes:boolean(0),$
     force:boolean(0),$
     no_cache:boolean(0),$
	 snap_skip:0b,$
     keep_directory:boolean(0),$
     update_log:'',$
     url:'',$
     file_cache:hash(),$
     dir_cache:hash(),$
	 fhash:hash(),$
	 dhash:hash(),$
	 slist:ptr_new(),$
     inherits dotprop,inherits gen }

return                                                                                            
end      
