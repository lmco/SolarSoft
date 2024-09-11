;+
; Project     : VSO
;
; Name        : URL_BREAK
;
; Purpose     : More robust rendition of PARSE_URL that uses REGEX
;
; Category    : utility sockets
;
; Syntax      : IDL> purl=url_break(url)
;
; Inputs      : URL = scalar string URL to parse
;
; Outputs     : PURL = structure with URL components parsed into:
;                      {scheme:'',username:'',password:'',host:'',port:'',path:'',query:''}
;
; Keywords    : None
;
; History     : 17-Jun-2022, Zarro (ADNET)
;
; Contact     : dzarro@solar.stanford.edu
;-


function url_break,url

if is_blank(url) then return,url

regex='([a-z]+://)?([^@/:]*:[^@/:]*@)?([^/:@]+)(:[0-9]*)?(/[^\?]*)?(\?.*)?'
p=stregex(url[0],regex,/extract,/sub,/fold)
purl={scheme:'',username:'',password:'',host:'',port:'',path:'',query:''}

scheme=p[1]
pos=strpos(scheme,':')
if pos gt 0 then purl.scheme=strmid(scheme,0,pos) else purl.scheme='http'

userpass=p[2]
pos1=strpos(userpass,':') & pos2=strpos(userpass,'@')

if (pos1 gt 0) then purl.username=strmid(userpass,0,pos1)
if ((pos2-pos1-1) gt 0) then purl.password=strmid(userpass,pos1+1,pos2-pos1-1)

purl.host=p[3]

port=p[4]
pos=strpos(port,':')
if pos eq 0 then purl.port=strmid(port,1,strlen(port))

path=p[5]
pos=strpos(path,'/')
if pos eq 0 then purl.path=strmid(path,1,strlen(path))

query=p[6]
pos=strpos(query,'?')
if pos eq 0 then purl.query=strmid(query,1,strlen(query))

return,purl
end


