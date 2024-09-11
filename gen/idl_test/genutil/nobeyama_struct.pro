function nobeyama_struct, number, version=version, $
	oldversion=olversion, update=update

;+
;   Name: nobeyama_struct
;
;   Purpose: return nobeyama_structure 
;
;   Input Parameters:
;      number (optional) - number structures returned  - default is one  
;  
;   Keyword Parameters:
;      catalog - if set, return catalog structure (subset)
;
;   Calling Sequence:
;      str=nobeyama_struct( [number] )
;
;   History:
;      27-apr-1996 S.L.Freeland (map FITs header)
;      24-may-1996 S.L.Freeland (add .VERSION, make .MJD long)
;      15-aug-1996 S.L.Freeland (Version 2, naxis3 - add /CATALOG switch)
;      27-oct-1996 S.L.Freeland (typo (BCALE->BSCALE))
;      11-dec-1996 S.L.Freeland (add /CATALOG keyword for testing)
;      11-feb-1997 S.L.Freeland (convert eit_struct->nobeyama_struct) 
;-

pad_size=128						; pad catalog struct
version=1

common	nobeyama_struct_blk, str, catstr

if keyword_set(oldversion) then version=oldversion

if n_elements(str) eq 0 then 					$
   case version of 
   1: str={							$

        version:1,						$

;	----------- fits ----------------------------
	simple:'', bitpix:0b, 					$
        naxis:3,naxis1:0,naxis2:0,naxis3:0,			$
        bscale:0., bzero:0., bunit:'',				$

;       ----------- soho ----------------------------
;
        date:'', mjd:0l, day:0, time:0l,			$
        time_obs:'',date_obs:'',				$
	filename:'',				                $
        origin:'', telescop:'', instrume:'', object:'',		$
        sci_obj:'', obs_prog:'',				$

;       -------- pointing -----------------------
	ctype1:'',  ctype2:'', ctype3:'',			$
	crpix1:0.,  crpix2:0., crpix3:0.,  			$
        crval1:0.,  crval2:0., crval3:0., 		        $
        cdelt1:0.,  cdelt2:0., cdelt3:0.,			$
        solar_r:0., solar_b0:0.,		                $
        SOLR:0. ,SOLP:0. ,SOLB:0,				$
        DEC:0., houra:0.,					$
  	AZIMUTH:0.,  ALTITUDE:0., 				$
        PMAT1:0., PMAT2:0., PMAT3:0., PMAT4:0.,			$          

;	----------- nobeyama -----------------------------
        jstdate:'',jsttime:'',jst_strt:'',jst_end:'',		$	
        startfrm:0l, endfrm:0l, polariz:'',att_10db:'',		$
        obs_freq:'', criter:0,ncompo:0, 		$
        ddoff1:0., ddoff2:0., mbeamc:'',			$

;       ---------------------------------------------------     
        comment:strarr(30)} 		
    else: message,/info,"Unexpected version number: " + strtrim(version,2)
endcase

outstr=str

if n_elements(number) gt 0 then outstr=replicate(outstr,long(number))

return,outstr
end


