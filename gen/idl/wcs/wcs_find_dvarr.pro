;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_DVARR
;
; Purpose     :	Read distortion table in FITS file
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation : This procedure reads a distortion look-up table from a FITS
;               file.  The procedure looks for an extension with the name
;               WCSDVARR and the requested extension version.
;
; Syntax      :	WCS_FIND_DVARR, FILENAME, EXTVER, HEADER, TABLE
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      :	FILENAME = Name of FITS file containing the table.
;
;               EXTVER   = Extension version to search for.
;
; Opt. Inputs :	None
;
; Outputs     : HEADER   = The header associated with the look-up table.
;
;               TABLE    = The look-up table.
;
;               If the requested extension is not found, then HEADER and TABLE
;               will be undefined.
;
; Opt. Outputs:	None
;
; Keywords    : ERRMSG	= If defined and passed, then any error messages will
;			  be returned to the user in this parameter rather than
;			  depending on the MESSAGE routine in IDL.  If no
;			  errors are encountered, then a null string is
;			  returned.  In order to use this feature, ERRMSG must
;			  be defined first, e.g.
;
;				ERRMSG = ''
;				WCS_FIND_DVARR, ERRMSG=ERRMSG, ...
;				IF ERRMSG NE '' THEN ...

;
; Calls       :	DELVARX, WCS_FIND_KEYWORD, DATATYPE, ADD_TAG, FXREAD
;
; Common      :	None
;
; Restrictions:	None
;
; Side effects: None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 09-May-2023, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_dvarr, filename, extver0, header, table, errmsg=errmsg
;
;  Make sure that FILENAME is a string scalar.
;
if (n_elements(filename) ne 1) or (datatype(filename) ne 'STR') then begin
    message = 'No filename passed'
    goto, handle_error
endif
;
;  Open the file.
;
message = ''
openr, unit, filename, /get_lun, error=error
if error ne 0 then begin
    message='Error opening '+filename
    goto, handle_error
endif
;
i_ext = 0
while not eof(unit) do begin
    message = ''
    fxhread, unit, header, status
    if status ne 0 then begin
        free_lun, unit
        message = 'Unable to read requested FITS header extension'
        goto, handle_error
    endif
;
;  Extract the keywords BITPIX, NAXIS, NAXIS1, ...
;
    bitpix = fxpar(header, 'bitpix')
    naxis  = fxpar(header, 'naxis')
    gcount = fxpar(header, 'gcount')
    if gcount eq 0 then gcount = 1
    pcount = fxpar(header, 'pcount')
    if naxis gt 0 then begin
        dims = fxpar(header,'naxis*') ;read dimensions
        ndata = dims[0]
        if naxis gt 1 then for i=2,naxis do ndata = ndata*dims[i-1]
    endif else ndata = 0
    nbytes = long64(abs(bitpix) / 8) * gcount * (pcount + ndata)
    nrec = (nbytes + 2879) / 2880
;
;  If this is the requested extension, then read the array.
;
    extname = fxpar(header, 'extname')
    extver  = fxpar(header, 'extver')
    if (strupcase(extname) eq 'WCSDVARR') and (extver eq extver0) then begin
;
;  Determine the array type from the keyword BITPIX.
;
        case bitpix of
            8:   idltype = 1    ; byte
            16:	 idltype = 2    ; integer*2
            32:	 idltype = 3    ; integer*4
            -32: idltype = 4    ; real*4
            -64: idltype = 5    ; real*8
        endcase
;
;  Read in the data.
;
        fxread, filename, table, newheader, ext=i_ext
;
;  Return the data.
;
        free_lun, unit
        return
    endif                       ;Extension found.
;
;  Otherwise, skip to the next extension.
;
    point_lun, -unit, pointlun          ;Current position
    mhead0 = pointlun + nrec * 2880l
    point_lun, unit, mhead0             ;Next fits extension
    i_ext = i_ext + 1
endwhile
;
;  The end-of-file was reached.
;
message = 'Requested extension not found'
;
handle_error:
delvarx, header, table
if n_elements(errmsg) ne 0 then begin
    errmsg = 'WCS_FIND_DVARR: ' + message
    return
end else message, message, /continue
end
