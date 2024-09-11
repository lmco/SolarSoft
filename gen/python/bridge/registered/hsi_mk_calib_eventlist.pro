                                                   
;+
; :Description:
;    This script generates an hsi_calib_eventlist data return as an array of
;    pointers (can be concatenated into a single structure) with info parameters
;    as well as writing the same data to a file
;
;
;
; :Keywords:
;    obj  - hsi_calib_eventlist instance
;    cbe_filename - name for fits file
;    info - info params after executing getdata()
;
; :Author: raschwar, 20-jul-2017
;-
function hsi_mk_calib_eventlist, obj=obj, cbe_filename = cbe_filename, info = info,_extra=extra

search_network
                                                                                         
obj = hsi_calib_eventlist(_extra=extra)                                                           
obj-> set, det_index_mask= [1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B, 1B],_extra=extra
obj-> set, im_energy_binning= [25.000000D, 50.000000D],_extra=extra                                    
obj-> set, im_time_interval= ['20-Feb-2002 11:05:58.000', '20-Feb-2002 11:06:31.330'],_extra=extra                                           
obj-> set, smoothing_time= 4.00000                                                        
obj-> set, time_bin_def= [1.00000, 2.00000, 2.00000, 4.00000, 8.00000, 16.0000, 16.0000, $
 32.0000, 64.0000],_extra=extra                                                                        
obj-> set, time_bin_min= 512L,_extra=extra                                                             
obj-> set, use_phz_stacker= 1L,_extra=extra                                                            
if is_string( cbe_filename ) then obj->write, cbe_filename = cbe_filename
info = obj->get( /info )
return, obj->getdata()
end
