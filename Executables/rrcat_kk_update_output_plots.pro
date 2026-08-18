PRO RRCAT_KK_UPDATE_OUTPUT_PLOTS, info

  IF info.refl_plot->ISCONTAINED('current') THEN BEGIN
    info.refl_plot->SETDATA,'current',*info.wn_r, *info.refl
  ENDIF ELSE BEGIN 
    info.refl_plot->ADD,*info.wn_r, *info.refl,name='current'
  ENDELSE
  xrange = [MIN(*info.wn_r), MAX(*info.wn_r)]
  yrange = [MIN(*info.refl), MAX(*info.refl)]
  info.refl_plot->setAxisProperty, xrange = xrange
  info.refl_plot->setAxisProperty, yrange = yrange
  info.refl_plot->show

  IF info.phase_plot->ISCONTAINED('current') THEN BEGIN
    info.phase_plot->SETDATA,'current',*info.wn_p, *info.phas
  ENDIF ELSE BEGIN 
    info.phase_plot->ADD,*info.wn_p, *info.phas,phas='current'
  ENDELSE
  xrange = [MIN(*info.wn_p), MAX(*info.wn_p)]
  yrange = [MIN(*info.phas), MAX(*info.phas)]
  info.phase_plot->setAxisProperty, xrange = xrange
  info.phase_plot->setAxisProperty, yrange = yrange
  info.phase_plot->show


END