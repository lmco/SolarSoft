;+
; Project     : VSO
;
; Name        : VSO_SERVER
;
; Purpose     : check and return available VSO proxy server and URI
;
; Category    : vso sockets
;
; Inputs      : None
;
; Outputs     : SERVER = VSO proxy server name
;
; Optional
;  Outputs    : URI = URI name
;
; Keywords    : NETWORK = 1 if network is up
;               NO_CHECK = return server and URI names without checking network status,
;
; History     : 1-Dec-2005,  D.M. Zarro (L-3Com/GSFC), Written
;               22-Dec-2005, J.Hourcle  (L-3Com/GSFC).  changed server; URI need not resolve
;               19-Nov-2010, J.Hourcle  (Wyle/GSFC).  Failover to SAO
;               or NAO, 'no_check' ignored
;               22-Mar-2010, Zarro (ADNET). Modified to 
;               return blank string instead of stopping on error.
;               27-Apr-2012, J.Hourcle.  look for environment var
;               'VSO_SERVER'
;               18-Dec-2012, Zarro 
;               - deprecated NO_CHECK
;               - fixed for loop check for proxies
;               22-Oct-2013, J.Hourcle, backup names for servers (DNS issues)
;               28-Sep-2014, J.Hourcle, more backup names
;               19-May-2017, J.Hourcle, routing around problem server
;				2018/03/12, J.B. Gurman, removed SAO from proxy list
;               20-Jun-2023, Zarro (ADNET), cleaned up proxies and added HTTPS support using IDL network objects
;               29-Jul-2023, Zarro (ADNET), added check for error message in case of failed connection
;
; Contact     : DZARRO@SOLAR.STANFORD.EDU
;-

function vso_server,uri,_ref_extra=extra,network=network,err=err

    network=0b
	use_network     ; set system variable to switch to IDL network objects

    uri='http://virtualsolar.org/VSO/VSOi'

;-- check endpoint (soap proxy)

    proxies = [ $
	 'https://sdo5.nascom.nasa.gov/cgi-bin/vsoi_tabdelim' $
	,'https://sdac.virtualsolar.org/cgi-bin/vsoi_tabdelim' $
	,'https://vso.nascom.nasa.gov/cgi-bin/vsoi_tabdelim' $ (backup DNS name)
     ]
    vso_env=getenv('VSO_SERVER')
    if is_string(vso_env) then proxies = [vso_env, proxies ]

    proxy = ''
    for i = 0, n_elements(proxies)-1 do begin
     proxy = proxies[i]
	 err=''
     network=have_network(proxy, _extra=extra,err=err)
     if ( network ) then return,proxy
    endfor
    
	if is_string(err) then mprint,err
    mprint, 'Failed to connect to VSO servers.'

	return,''
  
end
