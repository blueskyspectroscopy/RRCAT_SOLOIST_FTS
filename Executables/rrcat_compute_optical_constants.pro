;
; Use this program to read in reflectance and phase (computed
; using RRCAT_KK_TRANSFORM) and to calculate the following optical 
; constants:
; 
; refractive index, 
; dielectric constant, 
; optical conductivity
; 
; These values will be displayed in the GUI and saved to a file.
;
PRO RRCAT_COMPUTE_OPTICAL_CONSTANTS

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
  file_1_but = WIDGET_BUTTON(select_base, VALUE='Reflectance File', UVALUE='R_FILE_SELECT')
  file_2_but = WIDGET_BUTTON(select_base, VALUE='Phase File', UVALUE='PHASE_FILE_SELECT')

  opt_constants_base=widget_base(file_base,/col,/base_align_left,/frame)
  x=widget_label(opt_constants_base,/align_center,value='Optical Contansts')
  opt_constants_but = WIDGET_BUTTON(opt_constants_base, VALUE='COMPUTE Optical Contansts', UVALUE='COMPUTE_OPTICAL_CONSTANTS')
  opt_constants_save_but = WIDGET_BUTTON(opt_constants_base, VALUE='SAVE Results', UVALUE='SAVE_ALL')
  ;
  ;-------------------------------------------------------------------
  ;
  plot_base=widget_base(base,/col)
  refl_plot = BGPlot_widget(plot_base, Title='Reflectance',UValue='IFG Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Reflectance',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  n_plot = BGPlot_widget(plot_base, Title='Refractive index',UValue='SPC Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Refractive index',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  eps_plot_base=widget_base(base,/col)
  eps_plot = BGPlot_widget(eps_plot_base, Title='Dielectric constant',UValue='IFG Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Dielectric constant',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  sig_plot = BGPlot_widget(eps_plot_base, Title='Optical conductivity',UValue='SPC Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,2500],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Optical conductivity',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,renderer=renderer)

  info={tlb:tlb,$
    wn_r:ptr_new(!null),$
    refl:ptr_new(!null),$
    wn_p:ptr_new(!null),$
    phase:ptr_new(!null),$
    wn:ptr_new(!null),$
    n:ptr_new(!null),$
    epsilon:ptr_new(!null),$
    sigma:ptr_new(!null),$
    refl_plot:refl_plot,$
    n_plot:n_plot,$
    eps_plot:eps_plot,$
    sig_plot:sig_plot,$
    filename:'',$
    directory:'',$ ;default file directory
    widget_x_size:0l,$
    widget_y_size:0l,$
    widget_min_ysize:0l,$
    plot_avg:0,$    ;flag to plot average IFG and SPC
    autoscale_spc:1,$ ;autoscale SPC y axis
    autoscale_ifg_x:1,$ ;autoscale IFG x axis
    autoscale_ifg_y:0}  ;autoscale IFG y axis

  ;find y size of widget minus the plot y size.
  geo=widget_info(tlb,/geometry)
  info.widget_y_size=geo.ysize-plot_ysize*2 ;subtract the ysize of the two plot widgets
  info.widget_x_size=geo.xsize-plot_xsize ;subtract the xsize of the plot widgets

  geo=widget_info(file_base,/geometry)
  info.widget_min_ysize=geo.ysize+10

  Widget_Control, tlb, set_uvalue=info

  widget_control, tlb, /real, /show

  if widget_info(tlb, /valid) then  XManager, 'RRCAT_COMPUTE_OPTICAL_CONSTANTS', tlb, /No_Block


END