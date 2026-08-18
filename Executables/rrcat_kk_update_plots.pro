PRO RRCAT_KK_UPDATE_PLOTS, info, thePlot

  CASE thePlot OF
    1: BEGIN
      IF (*info.wn_1 NE !NULL) THEN BEGIN
        wn = *info.wn_1
        spec = *info.spec_1
        minWn = info.file_1_min_wn_field->get_value()
        maxWn = info.file_1_max_wn_field->get_value()
        wh = WHERE(wn GE minWn AND wn LE maxWn, whCount)
        IF whCount EQ 0 THEN RETURN
        wn = wn[wh]
        spec = spec[wh]
        ;col = WIDGET_INFO(info.file_1_color, /TABLE_BACKGROUND_COLOR)
        col = 'white'
        name='plot1'
      ENDIF
    END
    2: BEGIN
      IF (*info.wn_2 NE !NULL) THEN BEGIN
        wn = *info.wn_2
        spec = *info.spec_2
        minWn = info.file_2_min_wn_field->get_value()
        maxWn = info.file_2_max_wn_field->get_value()
        wh = WHERE(wn GE minWn AND wn LE maxWn, whCount)
        IF whCount EQ 0 THEN RETURN
        wn = wn[wh]
        spec = spec[wh]
        ;col = WIDGET_INFO(info.file_2_color, /TABLE_BACKGROUND_COLOR)
        col = 'red'
        name='plot2'
      ENDIF
    END
    3: BEGIN
      IF (*info.wn_3 NE !NULL) THEN BEGIN
        wn = *info.wn_3
        spec = *info.spec_3
        minWn = info.file_3_min_wn_field->get_value()
        maxWn = info.file_3_max_wn_field->get_value()
        wh = WHERE(wn GE minWn AND wn LE maxWn, whCount)
        IF whCount EQ 0 THEN RETURN
        wn = wn[wh]
        spec = spec[wh]
        ;col = WIDGET_INFO(info.file_3_color, /TABLE_BACKGROUND_COLOR)
        col = 'green'
        name='plot3'
      ENDIF
    END
    4: BEGIN
      IF (*info.wn_4 NE !NULL) THEN BEGIN
        wn = *info.wn_4
        spec = *info.spec_4
        minWn = info.file_4_min_wn_field->get_value()
        maxWn = info.file_4_max_wn_field->get_value()
        wh = WHERE(wn GE minWn AND wn LE maxWn, whCount)
        IF whCount EQ 0 THEN RETURN
        wn = wn[wh]
        spec = spec[wh]
        ;col = WIDGET_INFO(info.file_4_color, /TABLE_BACKGROUND_COLOR)
        col = 'blue'
        name='plot4'
      ENDIF
    END
  ENDCASE
  IF info.cur_spec_plot->ISCONTAINED('current') THEN BEGIN
    info.cur_spec_plot->SETDATA,'current',wn, spec 
  ENDIF ELSE BEGIN
    info.cur_spec_plot->ADD,wn, spec,name='current'
  ENDELSE
  xrange = [MIN(wn), MAX(wn)]
  yrange = [MIN(spec), MAX(spec)]
  info.cur_spec_plot->setAxisProperty, xrange = xrange
  info.cur_spec_plot->setAxisProperty, yrange = yrange
  info.cur_spec_plot->SetPlotProperty, color = 'yellow'
  info.cur_spec_plot->show

  IF info.tot_spec_plot->ISCONTAINED(name) THEN BEGIN
    info.tot_spec_plot->SETDATA,name,wn, spec
  ENDIF ELSE BEGIN
    info.tot_spec_plot->ADD,wn, spec,name=name,color=col
  ENDELSE
  ;  xrange = [MIN(wn), MAX(wn)]
  ;  yrange = [MIN(spec), MAX(spec)]
  ;  info.tot_spec_plot->setAxisProperty, xrange = xrange
  ;  info.tot_spec_plot->setAxisProperty, yrange = yrange
  info.tot_spec_plot->show


END