;+
; Project     :	STEREO
;
; Name        :	WCS_APPLY_DIST_TABLE
;
; Purpose     :	Apply distortion information in FITS header.
;
; Category    :	FITS, Coordinates, WCS
;
; Explanation : This procedure is called from WCS_GET_COORD to apply the
;               distortion lookup tables in the DISTORTION substructure.  
;
; Syntax      :	WCS_APPLY_DIST_TABLE, WCS, PIXELS, COORD  [, /PRIOR ]
;
; Examples    :	See wcs_get_coord.pro
;
; Inputs      :	WCS = A WCS structure, from FITSHEAD2WCS.
;               PIXELS = The requested pixel locations in the original array.
;                        The first dimension must correspond to the number of
;                        dimensions in the FITS file.
;               COORD  = The coordinate array to apply the distortions to.
;                        Must have the same dimensions are PIXELS.
;
; Opt. Inputs :	None.
;
; Outputs     : The input array COORD is returned with the distortion
;               corrections applied.
;
; Opt. Outputs:	None.
;
; Keywords    :	PRIOR = If set, then the prior distortion parameters are
;                       applied.  Otherwise, the subsequent distortion
;                       parameters are applied.
;
; Calls       :	VALID_WCS, TAG_EXIST, GET_TAG_INDEX, FITSHEAD2WCS, INTERPOLATE
;
; Common      :	None.
;
; Restrictions:	If any errors are found in the distortion keywords, then all
;               distortion keywords will be ignored.
;
; Side effects:	None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 11-May-2023, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_apply_dist_table, wcs, pixels, coord, prior=prior, solarnet=solarnet
on_error, 2
;
;  Check the WCS structure.
;
if not valid_wcs(wcs) then begin
    message, /continue, 'A valid WCS structure was not passed.'
    return
endif
;
;  If there is no DISTORTION substructure, then simply return.
;
if not tag_exist(wcs, 'distortion') then return
;
;  Check the pixel array.  The first dimension must match the number of axes.
;
if n_elements(pixels) eq 0 then begin
    message, /continue, 'No pixel array was passed.'
    return
endif
sz = size(pixels)
ndim = n_elements(wcs.naxis)
if ndim gt 1 then $
  if (sz[0] eq 0) or (sz[1] ne ndim) then begin
    message, /continue, 'PIXELS array has wrong dimensions'
    return
endif
;
;  Do the same for the coordinate array.
;
if n_elements(coord) eq 0 then begin
    message, /continue, 'No pixel array was passed.'
    return
endif
szc = size(coord)
ndim = n_elements(wcs.naxis)
if ndim gt 1 then $
  if (szc[0] eq 0) or (szc[1] ne ndim) then begin
    message, /continue, 'COORD array has wrong dimensions'
    return
endif
;
;  Make sure that PIXELS and COORD have the same dimensions.
;
npixels = n_elements(pixels)
ncoord = n_elements(coord)
if npixels ne ncoord then begin
    message, /continue, "PIXELS and COORD arrays don't match"
    return
endif
if npixels gt 0 then begin
    for i=1,sz[0] do if sz[i] ne szc[i] then begin
        message, /continue, "PIXELS and COORD arrays don't match"
        return
    endif
endif
;
;  Rearrange the input array into two dimensions, and define the correction
;  array.  Keep track of the original dimensions.
;
if sz[0] eq 0 then dim0 = 0 else dim0 = sz[1:sz[0]]
dim = [ndim, n_elements(pixels)/ndim]
pixels = reform(pixels, dim, /overwrite)
coord  = reform(coord,  dim, /overwrite)
corr = make_array(dimension=dim, /double)
;  
;
;  Step through the axes, and look for distortion parameters for that axis.
;
for iaxis = 1,ndim do begin
    if keyword_set(prior) then tag = 'DP' else tag = 'DQ'
    if n_elements(solarnet) eq 2 then tag = 'DW'
    tag = tag + ntrim(iaxis)
    if tag_exist(wcs.distortion, tag) then begin
        index = get_tag_index(wcs.distortion, tag)
        dist = wcs.distortion.(index)
        param = strupcase(dist.param)
        value = dist.value
;
;  Look for the function type.  If not defined, then the default is
;  "Polynomial".
;
        tag = 'CDIS'
        if tag_exist(dist, tag) then begin
            index = get_tag_index(dist, tag)
            dist_type = strupcase(dist.(index))
        end else dist_type = 'POLYNOMIAL'
;
;  Don't try to process non-lookup tables.
;
        if dist_type ne 'LOOKUP' then goto, next_axis
;
;  If the SOLARNET keyword was passed, check the ASSOCIATE and APPLY values.
;  If these don't match, then move on to the next axis.
;
        if n_elements(solarnet) eq 2 then begin
            w = where(param eq 'ASSOCIATE', count)
            if count eq 0 then begin
                message, /continue, $
                         'No ASSOCIATE keyword found for dimension ' + $
                         ntrim(iaxis)
                goto, reform
            endif
            associate = fix(value[w[0]])
            if associate ne solarnet[0] then goto, next_axis
;
            w = where(param eq 'APPLY', count)
            if count eq 0 then begin
                message, /continue, $
                         'No APPLY keyword found for dimension ' + $
                         ntrim(iaxis)
                goto, reform
            endif
            apply = fix(value[w[0]])
            if apply ne solarnet[1] then goto, next_axis
        endif                   ;SOLARNET option
;
;  Extract the lookup table header and data.  If not found, then quietly move
;  on to the next axis.
;
        if not tag_exist(dist, 'HEADER') then goto, next_axis
        if not tag_exist(dist, 'TABLE') then goto, next_axis
        header = dist.header
        table = dist.table
;
;  Get the number of independent variables in the distortion function.
;
        w = where(param eq 'NAXES', count)
        if count eq 0 then begin
            message, /continue, 'No NAXES keyword found for dimension ' + $
                     ntrim(iaxis)
            goto, reform
        endif
        naxes = fix(value[w[0]])
;
;  Create a position array for the table.
;
        sz = size(table)
        tpix = make_array(dimension=[naxes,dim[1]], /long)
;
;  Extract each independent variable.
;
        for jaxis = 1,naxes do begin
            par = 'AXIS.' + ntrim(jaxis)
            w = where(param eq par, count)
            if count eq 0 then begin
                message = 'No AXIS keyword found for term ' + ntrim(jaxis) + $
                          ' along dimension ' + ntrim(iaxis)
                goto, handle_error
            endif
            kaxis = fix(value[w[0]])
            tpix[jaxis-1,*] = pixels[kaxis-1,*]
;
;  Apply the offset and scale, if any.
;
            par = 'OFFSET.' + ntrim(jaxis)
            w = where(param eq par, count)
            if count gt 0 then begin
                offset = double(value[w[0]]) - 1 ;FITS->IDL notation
                tpix[jaxis-1,*] -= offset
            endif
            par = 'SCALE.' + ntrim(jaxis)
            w = where(param eq par, count)
            if count gt 0 then begin
                scale = double(value[w[0]])
                tpix[jaxis-1,*] *= scale
            endif
        endfor
;
;  Convert the original pixel locations into table locations.
;
        wcs_table = fitshead2wcs(header, /noprojection)
        tpix -= rebin(wcs_table.crval-1, naxes, dim[1])
        tpix /= rebin(wcs_table.cdelt  , naxes, dim[1])
        tpix += rebin(wcs_table.crpix-1, naxes, dim[1])
;
;  From the original pixels, calculate the pixel in the table.  If NAXES LE 3
;  then use interpolate.
;
        case naxes of
            1: term = interpolate(table, tpix[0,*])
            2: term = interpolate(table, tpix[0,*], tpix[1,*])
            3: term = interpolate(table, tpix[0,*], tpix[1,*], tpix[2,*])
;
;  Otherwise, just do nearest-neighbor.
;
            else: begin
                term = make_array(naxes, dim[1])
                tpix = round(tpix)
                w = dindgen(n_elements)
                for i=0,n_axis-1 do $
                  w = w[where((tpix[i,w] ge 0) and (tpix[i,w] lt wcs.naxis[i]))]
                command = 'term[w] = table[tpix[0,w]'
                for i=1,n_axis-1 do $
                  command = command + ',tpix[' + ntrim(i) + ',w]'
                command = command + ']'
                if not execute(command) then begin
                    message = 'Unable to execute command ' + command
                    goto, handle_error
                endif
            endcase
        endcase
        corr[iaxis-1,*] += term
    endif                       ;Distortion parameters exist for IAXIS
next_axis:
endfor                          ;Loop over IAXIS
;
;  Apply the correction, and skip over the error handling part.
;
coord = coord + corr
goto, reform
;
handle_error:
if n_elements(errmsg) ne 0 then $
  errmsg = 'WCS_APPLY_DIST_TABLE: ' + message else $
  message, message, /continue
;
;  Restore the original dimensions, and return.
;
reform:
if dim0[0] eq 0 then begin
    pixels = pixels[0]
    coord  = coord[0]
end else begin
    pixels = reform(pixels, dim0, /overwrite)
    coord  = reform(coord,  dim0, /overwrite)
endelse
return
;
end
