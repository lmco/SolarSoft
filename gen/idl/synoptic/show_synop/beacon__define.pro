;+
; Project     : STEREO
;
; Name        : BEACON__DEFINE
;
; Purpose     : stub that inherits from SECCHI class to process Beacon data
;
; Category    : Objects
;
; History     : 20-Nov-22, Zarro (ADNET), written
;
; Contact     : dzarro@solar.stanford.edu
;-

;-- init 

function beacon::init,_ref_extra=extra

ret=self->secchi::init(_extra=extra)
if ~ret then return,ret

ret=self->site::init(_extra=extra)
if ~ret then return,ret

;-- default to AHEAD EUVI

self->setprop,rhost='https://stereo-ssc.nascom.nasa.gov',/full,$
      org='day',topdir='/data/beacon/ahead/secchi/img/euvi',ext='fts'

return,1

end

;--------------------------------------------------------------------
;-- supported instruments

function beacon::instruments

insts=['cor2','euvi','hi_1','hi_2']

return,insts

end
;--------------------------------------------------------------------

function beacon::search,tstart,tend,_ref_extra=extra,instrument=instrument,ahead=ahead,behind=behind,verbose=verbose

verbose=keyword_set(verbose)
inst='euvi'
if is_string(instrument) then begin
 sinst=strlowcase(instrument)
 chk=where(sinst eq self->instruments(),count)
 if count eq 0 then begin
  mprint,'Unsupported instrument - '+instrument
  mprint,'Defaulting to EUVI.'
 endif else inst=sinst
endif

space='ahead'
if keyword_set(behind) then space='behind'

topdir='/data/beacon/'+space+'/secchi/img/'+inst
if verbose then mprint,'Searching - '+topdir
   
self->setprop,topdir=topdir

return,self->site::search(tstart,tend,_extra=extra)
end

;-----------------------------------------------------------------

;pro cor1::read,file,_ref_extra=extra

;self->secchi::read,file,det='cor1',_extra=extra

;return

;end

;------------------------------------------------------
pro beacon__define,void                 

void={beacon, inherits secchi, inherits site}

return & end
