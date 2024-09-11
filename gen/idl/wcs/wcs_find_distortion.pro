;+
; Project     :	STEREO
;
; Name        :	WCS_FIND_DISTORTION
;
; Purpose     :	Find distortion information in FITS header
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation : This procedure extracts distortion information from a FITS
;               index structure, and adds it to a World Coordinate System
;               structure in a separate DISTORTION substructure.
;
;               This routine is normally called from FITSHEAD2WCS.
;
; Syntax      :	WCS_FIND_TIME, INDEX, TAGS, SYSTEM, WCS
;
; Examples    :	See fitshead2wcs.pro
;
; Inputs      :	INDEX  = Index structure from FITSHEAD2STRUCT.
;               TAGS   = The tag names of INDEX
;               SYSTEM = A one letter code "A" to "Z", or the null string
;                        (see wcs_find_system.pro).
;               WCS    = A WCS structure, from FITSHEAD2WCS.
;
; Opt. Inputs :	None.
;
; Outputs     : The output is the structure DISTORTION, which will contain one
;               or more of the following parameters, depending on the contents
;               of the FITS header:
;
;                       DPi (i=1,2,...)         prior distortion
;                       DQi (i=1,2,...)         subsequent distortion
;                       DWi (i=1,2,...)         SOLARNET distortion
;                       DVERR                   Maximum of all distortions
;
;               The DPi, DQi, and DWi parameters are themselves structures with
;               the following parameters:
;
;                       PARAM   Array of distortion parameter names
;                       VALUE   Array of distortion parameter values
;                       CDIS    Distortion function type
;                       CERR    Array of maximum distortions per axis
;
; Opt. Outputs:	None.
;
; Keywords    :	COLUMN    = String containing binary table column number, or
;                           the null string.
;
;               LUNFXB    = The logical unit number returned by FXBOPEN,
;                           pointing to the binary table that the header
;                           refers to.  Usage of this keyword allows
;                           implementation of the "Greenbank Convention",
;                           where keywords can be replaced with columns of
;                           the same name.
;
;               ROWFXB    = Used in conjunction with LUNFXB, to give the
;                           row number in the table.  Default is 1.
;
;               FILENAME = Name of original FITS file, used to support
;                          distortion look-up tables.  If omitted, then
;                          distortions along that axis are ignored.
;
; Calls       :	DELVARX, WCS_FIND_KEYWORD, DATATYPE, ADD_TAG
;
; Common      :	None.
;
; Restrictions:	The "Lookup" distortion type is not yet handled.
;
;               If any errors are found in the distortion keywords, then all
;               distortion keywords will be ignored.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 28-Jun-2019, William Thompson, GSFC
;               Version 2, 09-May-2023, WTT, include SOLARNET DW forms
;                       Incorporate lookup tables
;               Version 3, 10-May-2023, WTT, keep track of SOLARNET ASSOCIATE
;                       and APPLY values.
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_find_distortion, index, tags, system, wcs, column=column, $
                         lunfxb=lunfxb, rowfxb=rowfxb, filename=filename
on_error, 2
if n_elements(column) eq 0 then column=''
;
;  Determine the number of axes that can potentially have distortion parameters
;  associated with them.
;
naxes = n_elements(wcs.naxis)
;
;  For each axis, look for the following keywords and values.
;
;       CPDISj  Prior distortion function type
;       CQDISi  Subsequent distortion function type
;       CWDISj  SOLARNET distortion function type
;       DPj     Prior distortion parameter
;       DQj     Subsequent distortion parameter
;       DWj     SOLARNET distortion parameter
;       CPERRj  Maximum prior correction for axis j
;       CQERRj  Maximum subsequent correction for axis j
;       CWERRj  Maximum SOLARNET correction for axis j
;
delvarx, distortion, solarnet_associate, solarnet_apply
for iaxis = 1,naxes do begin
    delvarx, dp, dq, dw
;
;  First look for the DPj keywords.
;
    str = wcs_find_keyword(index, tags, column, system, count, $
                           'DP'+ntrim(iaxis), ntrim(iaxis)+'DP', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  Parse the keywords.
;
        nstr = n_elements(str)
        param = strarr(nstr)
        value = param
        for i=0,nstr-1 do begin
            len = strlen(str[i])
            colon = strpos(str[i], ':')
            if colon lt 1 then begin
                message, /continue, 'Malformed distortion keyword ' + str
                return
            endif
            param[i] = strmid(str[i], 0, colon)
            value[i] = strtrim(strmid(str[i], colon+1, len-colon-1), 2)
        endfor
;
;  Get the additional keywords.
;
        name = 'CPDIS' + ntrim(iaxis)
        cpdis = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if datatype(cpdis) ne 'STR' then cpdis = 'Polynomial'
        dp = {param: param, value: value, cdis: cpdis}
;
        name = 'CPERR' + ntrim(iaxis)
        cperr = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if count gt 0 then dp = add_tag(dp, cperr, 'cerr')
;
;  If the distortion type is lookup, then read in the lookup table.
;
        if cpdis eq 'Lookup' then begin
            w = where(strupcase(param) eq 'EXTVER', count)
            if count gt 0 then begin
                extver = fix(value[w[0]])
                message = ''
                wcs_find_dvarr, filename, extver, header, table, errmsg=message
                if message eq '' then begin
                    dp = add_tag(dp, header, 'header')
                    dp = add_tag(dp, table, 'table')
                endif
            endif
        endif            
;
;  Add the distortion description.
;
        distortion = add_tag(distortion, dp, 'DP' + ntrim(iaxis))
    endif
;
;  Next, look for the DQi keywords.
;
    str = wcs_find_keyword(index, tags, column, system, count, $
                           'DQ'+ntrim(iaxis), ntrim(iaxis)+'DQ', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  Parse the keywords.
;
        nstr = n_elements(str)
        param = strarr(nstr)
        value = param
        for i=0,nstr-1 do begin
            len = strlen(str[i])
            colon = strpos(str[i], ':')
            if colon lt 1 then begin
                message, /continue, 'Malformed distortion keyword ' + str
                return
            endif
            param[i] = strmid(str[i], 0, colon)
            value[i] = strtrim(strmid(str[i], colon+1, len-colon-1), 2)
        endfor
;
;  Get the additional keywords.
;
        name = 'CQDIS' + ntrim(iaxis)
        cqdis = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if datatype(cqdis) ne 'STR' then cqdis = 'Polynomial'
        dq = {param: param, value: value, cdis: cqdis}
;
        name = 'CQERR' + ntrim(iaxis)
        cqerr = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if count gt 0 then dq = add_tag(dq, cqerr, 'cerr')
;
;  If the distortion type is lookup, then read in the lookup table.
;
        if cqdis eq 'Lookup' then begin
            w = where(strupcase(param) eq 'EXTVER', count)
            if count gt 0 then begin
                extver = fix(value[w[0]])
                message = ''
                wcs_find_dvarr, filename, extver, header, table, errmsg=message
                if message eq '' then begin
                    dq = add_tag(dq, header, 'header')
                    dq = add_tag(dq, table, 'table')
                endif
            endif
        endif            
;
;  Add the distortion description.
;
        distortion = add_tag(distortion, dq, 'DQ' + ntrim(iaxis))
    endif
;
;  Next, look for the DWi keywords.
;
    str = wcs_find_keyword(index, tags, column, system, count, $
                           'DW'+ntrim(iaxis), ntrim(iaxis)+'DW', $
                           lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then begin
;
;  Parse the keywords.
;
        nstr = n_elements(str)
        param = strarr(nstr)
        value = param
        for i=0,nstr-1 do begin
            len = strlen(str[i])
            colon = strpos(str[i], ':')
            if colon lt 1 then begin
                message, /continue, 'Malformed distortion keyword ' + str
                return
            endif
            param[i] = strmid(str[i], 0, colon)
            value[i] = strtrim(strmid(str[i], colon+1, len-colon-1), 2)
        endfor
;
;  Get the additional keywords.
;
        name = 'CWDIS' + ntrim(iaxis)
        cwdis = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if datatype(cwdis) ne 'STR' then cwdis = 'Polynomial'
        dw = {param: param, value: value, cdis: cwdis}
;
        name = 'CWERR' + ntrim(iaxis)
        cwerr = wcs_find_keyword(index, tags, column, system, count, $
                                 name, name, lunfxb=lunfxb, rowfxb=rowfxb)
        if count gt 0 then dw = add_tag(dw, cwerr, 'cerr')
;
;  Collect the ASSOCIATE and APPLY parameters.
;
        w = where(param eq 'ASSOCIATE', count)
        if count eq 0 then begin
            message, /continue, $
                     'ASSOCIATE parameter missing in distortion description'
            associate = 0
        end else associate = fix(value[w[0]])
        boost_array, solarnet_associate, associate
;
        w = where(param eq 'APPLY', count)
        if count eq 0 then begin
            message, /continue, $
                     'APPLY parameter missing in distortion description'
            apply = 0
        end else apply = fix(value[w[0]])
        boost_array, solarnet_apply, apply
;
;  If the distortion type is lookup, then read in the lookup table.
;
        if cwdis eq 'Lookup' then begin
            w = where(strupcase(param) eq 'EXTVER', count)
            if count gt 0 then begin
                extver = fix(value[w[0]])
                message = ''
                wcs_find_dvarr, filename, extver, header, table, errmsg=message
                if message eq '' then begin
                    dw = add_tag(dw, header, 'header')
                    dw = add_tag(dw, table, 'table')
                endif
            endif
        endif            
;
;  Add the distortion description.
;
        distortion = add_tag(distortion, dw, 'DW' + ntrim(iaxis))
    endif
endfor
;
;  If any distortion parameters were found, then also look for the DVERR
;  keyword.
;
if n_elements(distortion) gt 0 then begin
    dverr = wcs_find_keyword(index, tags, column, system, count, $
                             'DVERR', 'DVERR', lunfxb=lunfxb, rowfxb=rowfxb)
    if count gt 0 then $
      distortion = add_tag(distortion, dverr, 'dverr', /top_level)
;
;  If any SOLARNET distortions were found, then add those to the DISTORTION
;  structure.
;
    if n_elements(solarnet_associate) gt 0 then begin
        distortion = add_tag(distortion, solarnet_associate[*], 'associate', $
                             /top_level)
        distortion = add_tag(distortion, solarnet_apply[*], 'apply', $
                             /top_level)
    endif
;
;  Add the DISTORTION tag to the WCS structure.
;
    if tag_exist(wcs, 'DISTORTION', /top_level) then $
      wcs = rem_tag(wcs, 'DISTORTION')
    wcs = add_tag(wcs, distortion, 'DISTORTION', /top_level)
endif
;
return
end
