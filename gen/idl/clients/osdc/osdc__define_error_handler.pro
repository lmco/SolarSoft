compile_opt idl2, strictarr, strictarrsubs
catch, oops_error
IF oops_error NE 0 THEN BEGIN
   catch, /cancel
   msg = [ "** Oops, an error occurred! Please email", $
           "", $
           "      prits-group@astro.uio.no", $
           "", $
           "** unless you can figure it out or the problem goes away after a few", $
           "** minutes. Please include the error message below and any other", $
           "** information you think may be relevant" $
         ]
   print
   box_message, msg
   print
   message, /reissue_last
END
