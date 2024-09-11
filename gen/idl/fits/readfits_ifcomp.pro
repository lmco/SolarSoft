;+
; Project     :	General
;
; Name        :	READFITS_IFCOMP
;
; Purpose     :	Reads FITS files which may or may not use compression.
;
; Category    :	I/O
;
; Explanation :	Determines whether or not a FITS file is compressed, and uses
;               the appropriate routines to read the file.
;
; Syntax      :	IMAGE = READFITS_IFCOMP(FILENAME, HEADER)
;
; Examples    :	FILE = 'solo_L1_eui-hrieuv174-image_20210326T231700254_V01.fits'
;               IMAGE = READFITS_IFCOMP(FILE, HEADER)
;
; Inputs      :	FILENAME = The name of the FITS file
;
; Opt. Inputs :	None
;
; Outputs     :	IMAGE   = The image contained within the file.
;
; Opt. Outputs:	HEADER  = String array containing the FITS header.
;
; Keywords    : OUT_DIR = Output directory for decompressed file.
;
;               NODELETE = If set, and the original file is compressed, then
;                          the (otherwise temporary) decompressed file is not
;                          deleted.
;
;               ERRMSG  = If defined and passed, then any error messages will
;                         be returned to the user in this parameter rather than
;                         depending on the MESSAGE routine in IDL.  If no
;                         errors are encountered, then a null string is
;                         returned.  In order to use this feature, ERRMSG must
;                         be defined first, e.g.
;
;                               ERRMSG = ''
;                               A = READFITS_IFCOMP(ERRMSG=ERRMSG, ...)
;                               IF ERRMSG NE '' THEN ...
;
;               Keywords (e.g. NOSCALE, NO_UNSIGNED) can also be passed through
;               to READFITS, though not all keywords may be appropriate for
;               compressed files.
;
; Calls       :	IS_RICE_COMP, RICE_DECOMP, READFITS
;
; Common      :	None.
;
; Restrictions:	This routine is intended for otherwise simple FITS files which
;               might or might not use FITS compression, and does not support
;               all capabilities of READFITS for files using compression.
;
;               Requires $SSW/vobs/ontology to be installed.
;
;               Currently, only RICE compression is supported.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1,  9-Jun-2022, William Thompson, GSFC
;               Version 2, 10-Jun-2022, WTT, added on_error statement
;
; Contact     :	WTHOMPSON
;-
;
function readfits_ifcomp, filename, header, nodelete=nodelete, errmsg=errmsg, $
                          _extra=_extra
on_error, 2
;
;  If the file is RICE compressed, then decompress it first.
;
if is_rice_comp(filename) then begin
    temp = rice_decomp(filename, err=message, _extra=_extra)
    if message ne '' then goto, handle_error
;
;  Read the temporary file.
;
    message, /reset
    image = readfits(temp, header, _extra=_extra)
    if not keyword_set(nodelete) then file_delete, temp
;
;  If not compressed, then simply read the file.
;
end else begin
    message, /reset
    image = readfits(filename, header, _extra=_extra)
endelse
;
if !error_state.code lt 0 then begin
    message = !error_state.msg
    goto, handle_error
endif
;
return, image
;
;  Error handling point.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message else $
  errmsg = 'READFITS_IFCOMP: ' + message
;
end
