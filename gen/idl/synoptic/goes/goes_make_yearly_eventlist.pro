;+
; Name: goes_make_yearly_eventlist
;
; Purpose: Create ascii list of GOES events for a given year
;
; Calling sequence:  goes_make_yearly_eventlist, year=year, nyear=neary, file=file, list=list
;
; Input keywords:
;  year - year to run (e.g. 2011 or '2011'), default is current year
;  nyear - number of years to run, starting with year specified, default is 1
;  filestart - beginning of output file name (complete file name will be
;    filestart+year.txt). Default is ''goes_xray_event_list_'
;  archive - if set, then we're writing files for the GOES event archive on hesperia, so if
;    current time is within three weeks of the beginning of the year, write the previous
;    year as well (to make sure previous year is complete)
;
; Output keywords:
;  list - text list of events created
;
; Kim Tolbert, December 2011
; Modifications:
; 22-Aug-2013, Kim.  Added program name, original NOAA site URL, and column info to header of output file
; 05-May-2022, Kim.  Added yohkoh keyword because added HER to goes::get_gev as source of event listings (and HER will be
;    default in the future.
;    Until S. Freeland fixes HER source files, make two yearly listigs one in $GOES_FITS/goes_event_listings and one in
;    $GOES_FITS/goes_event_listings_HER (by calling this twice with yohkoh=0/1). Changed text in header of out file to
;    show source of events.
;
;-

pro goes_make_yearly_eventlist, year=year, nyear = nyear, $
  filestart=filestart, archive=archive, $
  list=list, yohkoh=yohkoh

  checkvar, nyear, 1
  checkvar, filestart, 'goes_xray_event_list_'
  checkvar, archive, 0

  if ~keyword_set(year) then year = (anytim(/ext,!stime))[6]
  year = trim(year)

  ; if writing archive and current time is within 21 days of beginning of year, write previous year too
  if archive and (anytim(!stime) - anytim('1-jan-'+year) lt 3.*7.*86400.) then begin
    year = trim(fix(year)-1)
    nyear = 2
  endif

  ts = anytim('1-jan-'+year, /ext)
  te = anytim('31-Dec-'+year, /ext)


  g=ogoes()

  for i=0,nyear-1 do begin
    g->set,tstart=anytim(ts,/vms),tend=anytim(te,/vms)
    a=g->get_gev(yohkoh=yohkoh)
    if is_string(a[0]) then begin
      nevent = n_elements(a)
      year=trim(ts[6])
      archive_name = keyword_set(yohkoh) ? 'Yohkoh archive of NOAA-defined events' : 'Heliophysics Event Registry (HER)'
      list = ['GOES XRAY events for ' + year, $
        'Written ' + anytim(!stime,/date,/vms) + ', Kim Tolbert, kim.tolbert@nasa.gov, by goes_make_yearly_eventlist.pro', $
        trim(nevent) + ' events were retrieved from the ' + archive_name, $
        '', $
        'Columns: Date, Start, Peak, End Time, Class, Position (if available), Active Region (if available)', $
        '', $
        a]
      file = filestart+trim(ts[6])+'.txt'
      prstr, list, file=file
      if archive and file_test(file, /read) then begin
        arch_dir = keyword_set(yohkoh) ? '$GOES_FITS/goes_event_listings' : '$GOES_FITS/goes_event_listings_HER'
        file_move, file, arch_dir, /overwrite
        print, 'Moved ' + file + ' to ' + arch_dir
      endif else print,'Not moving file to archive'
    endif
    ts[6]=ts[6]+1 & te[6]=te[6]+1
  endfor

  destroy,g

end
