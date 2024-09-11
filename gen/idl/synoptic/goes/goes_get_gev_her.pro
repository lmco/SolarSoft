;+
; Name: goes_get_gev_her
; 
; Purpose: Get GOES event listing from Heliophysics Event Registry (HER)
; 
; Input Keywords:
;   timerange - time range to get events for in anytim format
;   full_struct - return the full structure returned from HER (otherwise condensed structure described below
;   quiet - if set, don't print info messages
;   
; Output - return array of structures with the following tags:
;   gstart - start time of event
;   gpeak - peak time of event
;   gend - end time of event
;   loc - location of event
;   class - GOES class of event
;   ar - Active Region in which event occurred
;   
; Written: Kim Tolbert, 20-Apr-2022
; Modifications:
; 
;-

function goes_get_gev_her, timerange=tr, full_struct=full_struct, quiet=quiet

  loud = 1 - keyword_set(quiet)

  checkvar, tr, ['1-jan-2022','2-jan-2022']
  if n_elements(tr) ne 2 then tr = anytim(tr) + [0.,86400.]
  tr = anytim(tr, /vms)

  if loud then mprint,'Retrieving GEV data for '+ tr[0] + ' to ' + tr[1],/cont

  if ~have_proc('ssw_her_make_query') then begin
    ssw_path,/ontology,/quiet
    if ~have_proc('ssw_her_make_query') then begin
      err='VOBS/Ontology branch of SSW not installed. Aborting.'
      mprint,err,/info
      return, -1
    endif
  endif
  
  f_struct = ssw_her_query(ssw_her_make_query(tr[0], tr[1], /FL, search=['FRM_NAME=SSW Latest Events']), /all_pages)
  ;  f_struct = ssw_her_query(ssw_her_make_query(tr[0], tr[1], /FL,search=['obs_observatory=GOES']))

  if keyword_set(full_struct) then return, f_struct

  if ~is_struct(f_struct) then return, -1

  fl = f_struct.fl
  nfl = n_elements(fl)

  ; Remove any duplicates (might have slightly different positions)
  if nfl gt 1 then begin
    q = where(fl[0:nfl-2].event_starttime eq fl[1:nfl-1].event_starttime and $
      fl[0:nfl-2].event_endtime eq fl[1:nfl-1].event_endtime and $
      fl[0:nfl-2].ar_noaanum eq fl[1:nfl-1].ar_noaanum, nq)
    if nq gt 0 then remove, q+1, fl  ; remove second of each pair of dupilicates
  endif

  nfl = n_elements(fl)
  if loud then print, trim(nfl) + ' events found.'

  ns = strarr(nfl) + 'N'  ; north / south
  q = where(fl.event_coord2 lt 0, nq)
  if nq gt 0 then ns[q] = 'S'
  ew = strarr(nfl) + 'W'  ; east / west
  q = where(fl.event_coord1 lt 0, nq)
  if nq gt 0 then ew[q] = 'E'
  loc = ns + trim(abs(fl.event_coord2), '(i2.2)') + ew + trim(abs(fl.event_coord1), '(i2.2)')
  
  ; Active region should have '1' in front (or '10' for 3 digit ar).  But if it was zero, then make it a blank string.
  ar = trim(fix(fl.ar_noaanum) + 10000)
  q = where(ar eq 10000, nq)
  if nq gt 0 then ar[q] = ''

  out_struct = {gstart: fl.event_starttime, $
    gpeak:  fl.event_peaktime, $
    gend:   fl.event_endtime, $
    loc:    loc, $
    class:  fl.fl_goescls, $
    ar:     ar}

  out_struct = reform_struct(out_struct)

  return, out_struct

  ; head = ['Columns: Date, Start, Peak, End Time, Class, Position (if available), Active Region (if available)', $

  ;  sp = '   '
  ;  out_string = strmid(anytim(out_struct.gstart,/vms), 0, 17) + sp + $
  ;   strmid(anytim(out_struct.gpeak,/vms), 12, 5) + sp + $
  ;   strmid(anytim(out_struct.gpeak,/vms), 12, 5) + sp + $
  ;   class + sp + loc + sp + ar
end