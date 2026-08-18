PRO RRCAT_KK_TRANSFORM

  plot_xsize=680
  plot_ysize=320  ;this should be larger than the tab widget height during initialization.

  tlb=widget_base(/col,title=title,/tlb_size_events, mbar=bar);, $
  ;notify_realize='RRCAT_KK_TRANSFORM_REALIZE', kill_notify='RRCAT_KK_TRANSFORM_KILL')

  file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU)
  x=WIDGET_BUTTON(file_menu, VALUE='Quit', UVALUE='QUIT')

  option_menu = WIDGET_BUTTON(bar, VALUE='Options', /MENU)
  x=WIDGET_BUTTON(option_menu, VALUE='Set Data Directory', UVALUE='DIRECTORY')

  base=widget_base(tlb,/row,tab_mode=1)

  file_base=widget_base(base, uvalue='NULL',/col,/base_align_left,/frame)

  parm_base=widget_base(file_base,/row,/base_align_left,/frame)
  select_base = widget_base(parm_base,/col,/base_align_center)
  x = WIDGET_LABEL(select_base, Value='Select')
  file_1_but = WIDGET_BUTTON(select_base, VALUE='File 1', UVALUE='FILE_1_SELECT')
  file_2_but = WIDGET_BUTTON(select_base, VALUE='File 2', UVALUE='FILE_2_SELECT')
  file_3_but = WIDGET_BUTTON(select_base, VALUE='File 3', UVALUE='FILE_3_SELECT')
  file_4_but = WIDGET_BUTTON(select_base, VALUE='File 4', UVALUE='FILE_4_SELECT')

  min_base = widget_base(parm_base,/col,/base_align_center)
  x = WIDGET_LABEL(min_base, Value='Min. Wn (cm-1)')
  file_1_min_wn_field=fsc_inputfield(min_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MIN_WN_1', value = 0.)
  file_2_min_wn_field=fsc_inputfield(min_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MIN_WN_2', value = 100.)
  file_3_min_wn_field=fsc_inputfield(min_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MIN_WN_3', value = 800.)
  file_4_min_wn_field=fsc_inputfield(min_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MIN_WN_4', value = 1500.)

  max_base = widget_base(parm_base,/col,/base_align_center)
  x = WIDGET_LABEL(max_base, Value='Max. Wn (cm-1)')
  file_1_max_wn_field=fsc_inputfield(max_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MAX_WN_1', value = 100.)
  file_2_max_wn_field=fsc_inputfield(max_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MAX_WN_2', value = 800.)
  file_3_max_wn_field=fsc_inputfield(max_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MAX_WN_3', value = 1500.)
  file_4_max_wn_field=fsc_inputfield(max_base,/float,title='',/cr_only,xsize=12,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MAX_WN_4', value = 2500.)

;  color_base = widget_base(parm_base,/col,/base_align_center)
;  x = WIDGET_LABEL(color_base, Value='Color',xsize=40)
;  file_1_color = WIDGET_TABLE(color_base, VALUE=[''], UVALUE='FILE_1_COLOR', $
;    BACKGROUND_COLOR = [255b, 255b, 255b], /NO_HEADERS, XSIZE=1, YSIZE=1,event_pro='RRCAT_KK_TRANSFORM_Event',editable=0,$
;    column_widths=[20],scroll=0,sens=1, /ALL_EVENTS, FOREGROUND_COLOR = [255b, 255b, 255b])
;  file_2_color = WIDGET_TABLE(color_base, VALUE=[''], UVALUE='FILE_2_COLOR', $
;    BACKGROUND_COLOR = [255b, 0b, 0b], /NO_HEADERS, XSIZE=1, YSIZE=1,event_pro='RRCAT_KK_TRANSFORM_Event',editable=0,$
;    column_widths=[20],scroll=0,sens=1, /ALL_EVENTS)
;  file_3_color = WIDGET_TABLE(color_base, VALUE=[''], UVALUE='FILE_3_COLOR', $
;    BACKGROUND_COLOR = [0b, 255b, 0b], /NO_HEADERS, XSIZE=1, YSIZE=1,event_pro='RRCAT_KK_TRANSFORM_Event',editable=0,$
;    column_widths=[20],scroll=0,sens=1, /ALL_EVENTS)
;  file_4_color = WIDGET_TABLE(color_base, VALUE=[''], UVALUE='FILE_4_COLOR', $
;    BACKGROUND_COLOR = [0b, 0b, 255b], /NO_HEADERS, XSIZE=1, YSIZE=1,event_pro='RRCAT_KK_TRANSFORM_Event',editable=0,$
;    column_widths=[20],scroll=0,sens=1, /ALL_EVENTS)


  kk_base=widget_base(file_base,/col,/base_align_left,/frame)
  x=widget_label(kk_base,/align_center,value='K-K Parameters')
  high_f_field=fsc_inputfield(kk_base,/float,title='High Frequency Exponent',/cr_only,xsize=5,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='HIGH_F', value = -3.15)
  kk_min_wn_field=fsc_inputfield(kk_base,/float,title='Minimum Wavenumber (cm-1)',/cr_only,xsize=8,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MIN_WN', value = 0.)
  kk_max_wn_field=fsc_inputfield(kk_base,/float,title='Maximum Wavenumber (cm-1)',/cr_only,xsize=8,decimal=3,$
    /focus_events,event_pro='RRCAT_KK_TRANSFORM_Event',uvalue='MAX_WN', value = 2500.)
  kk_but = WIDGET_BUTTON(kk_base, VALUE='COMPUTE KK TRANSFORM', UVALUE='COMPUTE_KK')
  kk_save_but = WIDGET_BUTTON(kk_base, VALUE='SAVE Results', UVALUE='SAVE_KK')
  ;pal = CW_PALETTE_EDITOR(parm_base, uvalue='PALLETE')
  ;-------------------------------------------------------------------


  plot_base=widget_base(base,/col)
  cur_spec_plot = BGPlot_widget(plot_base, Title='Current Spectrum',UValue='IFG Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Reflectance',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  tot_spec_plot = BGPlot_widget(plot_base, Title='Total Spectrum',UValue='SPC Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Reflectance',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  out_plot_base=widget_base(base,/col)
  refl_plot = BGPlot_widget(out_plot_base, Title='Output Spectrum',UValue='IFG Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Reflectance',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  phase_plot = BGPlot_widget(out_plot_base, Title='Output Phase',UValue='SPC Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Phase',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  info={tlb:tlb,$
    wn_1:ptr_new(!null),$
    spec_1:ptr_new(!null),$
    wn_2:ptr_new(!null),$
    spec_2:ptr_new(!null),$
    wn_3:ptr_new(!null),$
    spec_3:ptr_new(!null),$
    wn_4:ptr_new(!null),$
    spec_4:ptr_new(!null),$
    wn_r:ptr_new(!null),$
    refl:ptr_new(!null),$
    wn_p:ptr_new(!null),$
    phas:ptr_new(!null),$
    cur_spec_plot:cur_spec_plot,$
    tot_spec_plot:tot_spec_plot,$
    refl_plot:refl_plot,$
    phase_plot:phase_plot,$
    filename:'',$
    directory:'',$ ;default file directory
    widget_x_size:0l,$
    widget_y_size:0l,$
    widget_min_ysize:0l,$
    plot_avg:0,$    ;flag to plot average IFG and SPC
    autoscale_spc:1,$ ;autoscale SPC y axis
    autoscale_ifg_x:1,$ ;autoscale IFG x axis
    autoscale_ifg_y:0,$ ;autoscale IFG y axis
    high_f_field:high_f_field,$
    kk_min_wn_field:kk_min_wn_field,$
    kk_max_wn_field:kk_max_wn_field,$
    file_1_min_wn_field:file_1_min_wn_field,$
    file_2_min_wn_field:file_2_min_wn_field,$
    file_3_min_wn_field:file_3_min_wn_field,$
    file_4_min_wn_field:file_4_min_wn_field,$
    file_1_max_wn_field:file_1_max_wn_field,$
    file_2_max_wn_field:file_2_max_wn_field,$
    file_3_max_wn_field:file_3_max_wn_field,$
    file_4_max_wn_field:file_4_max_wn_field};,$
;    file_1_color:file_1_color,$
;    file_2_color:file_2_color,$
;    file_3_color:file_3_color,$
;    file_4_color:file_4_color}

  ;find y size of widget minus the plot y size.
  geo=widget_info(tlb,/geometry)
  info.widget_y_size=geo.ysize-plot_ysize*2 ;subtract the ysize of the two plot widgets
  info.widget_x_size=geo.xsize-plot_xsize ;subtract the xsize of the plot widgets

  geo=widget_info(file_base,/geometry)
  info.widget_min_ysize=geo.ysize+10

  Widget_Control, tlb, set_uvalue=info

  widget_control, tlb, /real, /show

  if widget_info(tlb, /valid) then  XManager, 'RRCAT_KK_TRANSFORM', tlb, /No_Block


END