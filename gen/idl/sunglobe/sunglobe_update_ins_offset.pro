;+
; Project     :	ORBITER - SPICE
;
; Name        :	SUNGLOBE_UPDATE_INS_OFFSET
;
; Purpose     :	Updates instrument offset from spacecraft boresight
;
; Category    :	Object graphics, 3D, Planning, SPICE
;
; Explanation : Updates the instrument offsets in arcseconds from the
;               spacecraft boresight based on distance.
;
; Syntax      :	SUNGLOBE_UPDATE_INS_OFFSET, SSTATE
;
; Examples    :	See SUNGLOBE_DISTANCE
;
; Inputs      : SSTATE  = Widget top-level state structure.
;
; Calls       :	SUNGLOBE_GET_INS_OFFSET
;
; Restrictions: See SUNGLOBE_GET_INS_OFFSET
;
; History     :	Version 1, 21-Dec-2022, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro sunglobe_update_ins_offset, sstate
;
sunglobe_get_ins_offset, sstate, 'EUI/HRI/EUV', xoffset, yoffset
sstate.oeuieuv->setproperty, xoffset=xoffset
sstate.oeuieuv->setproperty, yoffset=yoffset
;
sunglobe_get_ins_offset, sstate, 'EUI/HRI/LYA', xoffset, yoffset
sstate.oeuilya->setproperty, xoffset=xoffset
sstate.oeuilya->setproperty, yoffset=yoffset
;
sunglobe_get_ins_offset, sstate, 'PHI', xoffset, yoffset
sstate.ophi->setproperty, xoffset=xoffset
sstate.ophi->setproperty, yoffset=yoffset
;
sunglobe_get_ins_offset, sstate, 'SPICE', xoffset, yoffset
sstate.ospice->setproperty, xoffset=xoffset
sstate.ospice->setproperty, yoffset=yoffset
;
if n_elements(wtopbase) eq 1 then widget_control, wtopbase, set_uvalue=sstate, /no_copy
;
end
