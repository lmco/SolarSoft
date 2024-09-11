pro show_pix, image, text, moon=moon, merc=merc, misc=misc, base0
;
;+
;   Name: show_pix
;
;   Purpose: dipslay processed images saved with mk_pix.pro
;
;   Calling Sequence: 
;      show_pix [/merc, /moon, /misc]
;      Widget version - file selection is intuitive now (?)
;
;   History:
;      7-Nov-1993 (SLF) Written for mercury picture display
;     10-Nov-1993 (SLF) allow r,g,b parameters, auto size window if too small
;     20-Dec-1993 (SLF) widgitized, some new features
;-
base0=widget_base(/column,title='Show Pix', xoff=0, yoff=0)
xmenu,['QUIT','XLOADCT','Delete Last','Hardcopy'],base0, $
	buttons=main_buts,/row


base1=widget_base(/column,/frame)
mlabel=widget_label(base1,value='Display Options',/frame)
xmenu,['Show Image', 'Show Documentation'],/nonexclusive, base0, $
	buttons=mode_buts,/row, uvalue=[1,1]

case 1 of
   keyword_set(moon): selsub='moon'
   keyword_set(misc): selsub='misc'
   keyword_set(merc): selsub='merc'
   else: selsub='misc'
endcase 
subdirs=dir_list('$DIR_SITE_GENPIX')
break_file,subdirs,sdl,sdp,sdf,sde,sdv 
which=wc_where(sdf,selsub,cnt)
if cnt ne 0 then begin
   files=findfile(subdirs(which(0)))
endif else begin
   files=strarr(10)
endelse

allpix=file_list(concat_dir('$DIR_SITE_GENPIX','*'),'*.genx')
break_file,allpix,apl,app,apf,apv,apf
big=max(strlen(apf))
most=max(deriv_arr(uniqo(app)))

base2=widget_base(/colum,/frame,base0)
flabel1=widget_label(base2,value='File Selection',/frame)
widget_control,set_uvalue=allpix,flabel1
base21=widget_base(/row,base2)
base21a=widget_base(/column,base21,/frame)
flabel21a=widget_label(base21a,value='Subdiretory',/frame,uvalue=sdf(which))
flist1=widget_list(base21a,value=sdf, uvalue=subdirs,ysize=n_elements(sdf))

pad=''
flab='File Name'
if big gt strlen(flab) then pad = string(replicate(32b,big/2+1))
flab=pad + flab + pad

files=str_replace(files,'.genx','')
base21b=widget_base(/column,base21,/frame)
flabel21b=widget_label(base21b,value=flab,/frame,uval='')
flist2=widget_list(base21b,value=files(0:(n_elements(files)-1)<10), $
	ysize=most, uvalue=files)

base3=widget_base(base0,/column)
flabel3=widget_label(base3,value='Current File',/frame)
ftext3=widget_text(base3,value=concat_dir('$DIR_SITE_GENPIX',sdf(which)))

captbase=widget_base(/column,title='Image Captions',yoff=400,xoff=0)
capttext=widget_text(captbase,ysize=30,xsize=80,/scroll)
;widget_control,captbase,/realize, group=base0, show=0
;widget_control,captbase, sensitive=0, map=0, show=0

uval=  {base:base0,			$
	mainbuts:main_buts,		$	; Quit et all.
	modebuts:mode_buts,		$	; image / documentaiont
	allfiles:flabel1,		$	; all under dir_site_genpix
	subdir:flabel21a,		$	; current sub directory
	file: flabel21b,		$	; current file
	slist:flist1,			$	; all subdirectories
	flist: flist2,			$	; all files in this sub
	current: ftext3,		$       ; text disp of current select
	captbase:captbase,		$	; caption base
	capttext:capttext		}       ; caption text (output)
	
widget_control,mode_buts(0),/set_button
widget_control,mode_buts(1),/set_button
widget_control,set_uvalue=uval, base0
widget_control,base0,/realize
xmanager,'show_pix',base0
return
end
