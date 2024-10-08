;+
; Project     : VSO
;
; Name        : UPDATE_HASH
;
; Purpose     : Update KEY/VALUE pair in a HASH object. 
;               If KEY is not present, KEY/VALUE will be added.
;               If KEY is present, old VALUE will be deleted and
;               replaced with new.
;
; Category    : objects, utility
;
; Syntax      : IDL> update_hash,hash,key,value
;
; Inputs      : HASH = HASH object
;               KEY = key name
;               VALUE = key value
;
; Outputs     : None
;
; Keywords    : GET = return VALUE associated with KEY
;               DELETE = delete KEY and associated value
;               ERR = error message
;               NO_COPY = do not copy value when adding/extracting
;
; History     : 25-November-2020, Zarro (ADNET) - written
;               14-May-2022, Zarro (ADNET) - added /NO_COPY
;
; Contact     : dzarro@solar.stanford.edu
;-

pro update_hash,hash,key,value,get=get,delete=delete,err=err,no_copy=no_copy
err=''

no_copy=keyword_set(no_copy)
get=keyword_set(get)
delete=keyword_set(delete)

bad=~is_hash(hash) || (n_elements(key) eq 0)
if ~bad then bad=get && (n_params() ne 3)

if bad then begin
 err='Missing/invalid input.'
 pr_syntax,'update_hash,hash,key,value,[/get, /delete]'
 return
endif

;-- if key doesn't exist, add key/value

chk=hash->haskey(key)
if (chk eq 0) && ~get && ~delete then begin
 if no_copy then hash[key]=temporary(value) else hash[key]=value
 return
endif

;-- return value if /get

if get then begin
 if chk eq 0 then begin
  value=null() 
  return
 endif
 if no_copy then value=hash->remove(key) else value=hash[key]
 return
endif

;-- delete key if /delete
 
if delete then begin
 if chk ne 0 then hash->remove,key 
 return
endif

;-- otherwise replace value 

if no_copy then hash[key]=temporary(value) else hash[key]=value

return
end
