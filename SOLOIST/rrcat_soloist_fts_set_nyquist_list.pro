;+
; NAME:
; RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST
;
; PURPOSE:
; This procedure is used to set up the list of available Nyquist frequencies depending
; on the FTS type. Modified for RRCAT because there are two lists, one for the PSO
; and one for the Laser
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST, Info
;
; INPUTS:
; Info: The main info block from RRCAT_SOLOIST_FTS.pro
; 
; KEYWORDS:
; INDEX: the index to set the current selection to. Must be provided if units are being changed.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Jun 19 2018.
;   Based on SOLOIST_FTS_SET_NYQUIST_LIST.
;-

pro RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST,info,index=ind

  if n_elements(ind) eq 0 then begin  ;if no index given, use the currently selected index. 
    result=SOLOIST_FTS_GET_NYQUIST(info, index=ind)
  endif

  ;update the nyquist field for the type of FTS
;  sampling=reverse((findgen(1000)+1)/1000.)  ;valid PSO intervals in mm. Minimum interval is 1um
  sampling_list=*info.sampling_list

  Case info.FTS_TYPE of
    'MZ':nyquist_list=1./(8.*sampling_list/10.) ;for MZ FTS
    else: nyquist_list=1./(4.*sampling_list/10.)  ;for Michelson
  endcase
  inds=where(nyquist_list gt 15) ;useful Nyquist values
  sampling_list=sampling_list[inds]
  nyquist_list=nyquist_list[inds]

  speed = info.speed_field->get_value()
  case info.freq_units of
    'ghz':widget_control,info.nyquist_id,set_value=string(wn2ghz(nyquist_list),format='(f0.2)')
    'wn':widget_control,info.nyquist_id,set_value=string(nyquist_list,format='(f0.2)')
    'hz':widget_control,info.nyquist_id,set_value=string(nyquist_list*speed,format='(f0.2)')
    else:message,'Unhandled frequency units!',/cont
  endcase

  *info.nyquist_list=nyquist_list
  *info.sampling_list=sampling_list

  ;set the list selection to the nearest to the previously set nyquist.
;assume that the nyquist list has the same length and order for all units
  widget_control,info.nyquist_id,set_combobox_select=ind

  return
end
