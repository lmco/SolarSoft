
function hv_euvi_hvs,filename

mrd_head,filename,header
header=fitshead2struct(header)  
image=0

case parse_stereo_name(header.obsrvtry, ['a','b']) of
    'a': details = hvs_euvi_a()
    'b': details = hvs_euvi_b()
endcase
;
;  Create the HVS structure.
;
break_file, filename, disk, dir, name, ext
dir = disk + dir
fitsname = name + ext
measurement = ntrim(header.wavelnth)
ext = anytim2utc(header.date_obs, /ext)
hvsi = {dir: dir, $
        fitsname: fitsname, $
        header: header, $
        comment: '', $
        measurement: measurement, $
        yy: string(ext.year, format='(I4.4)'), $
        mm: string(ext.month, format='(I2.2)'), $
        dd: string(ext.day, format='(I2.2)'), $
        hh: string(ext.hour, format='(I2.2)'), $
        mmm: string(ext.minute, format='(I2.2)'), $
        ss: string(ext.second, format='(I2.2)'), $
        milli: string(ext.millisecond, format='(I3.3)'), $
        details: details, $
        write_this: 'stereo'}

hvs = {img: temporary(image), hvsi: hvsi}

return,hvs

end
