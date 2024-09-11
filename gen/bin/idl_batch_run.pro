bat_start_time = systime(1)

.run $IDL_BATCH_RUN

bat_end_time = systime(1)
if (n_elements(bat_start_time) ne 0) then $
	print, getenv('IDL_BATCH_RUN'), ' took ', (bat_end_time-bat_start_time)/60, ' minutes to run'
exit
