;+
; NAME:
;	RRCAT_KK_TRANSFORM_EVENT
;
; PURPOSE:
;	This is the main event handler for RRCAT_KK_TRANSFORM.pro. All events are handled by this
;	code first.
;
; CATEGORY:
;	RRCAT KK Transform
;
; CALLING SEQUENCE:
;	RRCAT_KK_TRANSFORM_EVENT, Event
;
; INPUTS:
;	Event:	The widget event
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, Aug 21 2018.
;-


PRO RRCAT_KK_TRANSFORM_Event, event

  Widget_Control, event.top, Get_UValue=info

  if event.id eq event.top then begin
    ;the event came from the TLB. Resize the plot object
    ysize=event.y > info.widget_min_ysize 	;limit ysize so that the buttons don't get clipped.
    xsize=event.x > info.widget_x_size*2 	;limit xsize so that the plots aren't too small.

    widget_control,event.id, xsize=xsize, ysize=ysize
    info.cur_spec_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.tot_spec_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.cur_spec_plot->show
    info.tot_spec_plot->show

    info.refl_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.phase_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.refl_plot->show
    info.phase_plot->show
    return
  endif

  Widget_Control, event.id, Get_UValue=thisEvent

  CASE thisEvent OF
    'AUTO_IFG_X':begin
      widget_control,event.id,set_value='Lock IFG X Axis',set_uvalue='LOCK_IFG_X'
      info.autoscale_ifg_x=1
    end
    'AUTO_IFG_Y':begin
      widget_control,event.id,set_value='Lock IFG Y Axis',set_uvalue='LOCK_IFG_Y'
      info.autoscale_ifg_y=1
    end
    'AUTO_SPC_Y':begin
      widget_control,event.id,set_value='Lock SPC Y Axis',set_uvalue='LOCK_SPC_Y'
      info.autoscale_spc=1
    end
    'DIRECTORY':begin
      result=dialog_pickfile(path=info.directory,/directory,title='Choose a directory for spectral files')
      if result ne '' then info.directory=result
    end
    'HELP':begin
      ;soloist_fts_help
    end
    'IFG Plot Event': BEGIN
      case TAG_NAMES( event, /STRUCTURE_NAME) of
        'BGPLOTEVENT' : begin

        end
        else : stop
      endcase
    END
    'LOAD_SETTINGS':begin
    end
    'LOCK_IFG_X':begin
      widget_control,event.id,set_value='Autoscale IFG X Axis',set_uvalue='AUTO_IFG_X'
      info.autoscale_ifg_x=0
    end
    'LOCK_IFG_Y':begin
      widget_control,event.id,set_value='Autoscale IFG Y Axis',set_uvalue='AUTO_IFG_Y'
      info.autoscale_ifg_y=0
    end
    'LOCK_SPC_Y':begin
      widget_control,event.id,set_value='Autoscale SPC Y Axis',set_uvalue='AUTO_SPC_Y'
      info.autoscale_spc=0
    end
    'LOG_SPC':begin	;set logarithmic SPC scale
      widget_control,event.id,set_value='Linear Spectral Intensity',set_uvalue='LIN_SPC'
      info.spc_plot->getAxisProperty,yrange=yrange
      ;make sure existing plot range isn't negative
      yrange[0] = yrange[0] > 1e-9
      yrange[1] = yrange[1] > 1e-8
      info.spc_plot->setAxisProperty,yrange=yrange
      info.spc_plot->setAxisProperty,/ylog
      info.spc_plot->show
    end
    'LIN_SPC':begin	;set linear SPC scale
      widget_control,event.id,set_value='Log Spectral Intensity',set_uvalue='LOG_SPC'
      info.spc_plot->setAxisProperty,ylog=0
      info.spc_plot->show
    end
    'NULL':begin	;for widgets with meaningless events.
    end
    'OPEN':begin
      ;result=RRCAT_SOLOIST_FTS_READ_FILE(parent=info.tlb)
    end
    'PRINT' : begin
      ;create the printer object. This should normally be done at the main program level
      Printer = OBJ_NEW('IDLgrPrinter')
      Result = DIALOG_PRINTERSETUP(printer, DIALOG_PARENT=event.top)
      if result ne 0 then begin
        result = DIALOG_PRINTJOB(printer)
        if result ne 0 then begin
          info.ifg_plot->print,printer,/neg
          info.spc_plot->print,printer,/neg
        endif
      endif
      ;destroy the printer object. This should normally be done at the main program level
      ;or the printer will need to be configured each time.
      obj_destroy,printer
    end
    'QUIT': begin
      Widget_Control, event.top, /Destroy
      return
    end
    'SAVE_AVG':begin
      soloist_fts_write_spc,info,/avg
    end
    'SAVE_CURRENT':begin
      soloist_fts_write_spc,info
    end
    'SHOW_AVERAGE':begin
      widget_control,event.id,set_value='Hide Average',set_uvalue='HIDE_AVERAGE'
      info.ifg_plot->reveal,name='avg'
      info.spc_plot->reveal,name='avg'
      info.ifg_plot->show
      info.spc_plot->show
      info.hide_avg=0
    end
    'SHOW_CURRENT':begin
      widget_control,event.id,set_value='Hide Current',set_uvalue='HIDE_CURRENT'
      info.ifg_plot->reveal,name='current'
      info.spc_plot->reveal,name='current'
      info.ifg_plot->show
      info.spc_plot->show
      info.hide_current=0
    end
    'SPC_MOUSE':BEGIN
      info.spc_plot->mousemenu
    END
    'SPC Plot Event': BEGIN
      case TAG_NAMES( event, /STRUCTURE_NAME) of
        'BGPLOTEVENT' : begin

        end
        else : stop
      endcase
    END
    'FILE_1_SELECT':BEGIN
      file = dialog_pickfile(TITLE='Select File for Spectrum 1', PATH = info.directory)
      IF N_ELEMENTS(file) EQ 1 and file[0] EQ '' THEN BEGIN
        RETURN
      ENDIF
      read_spc, file, wn, spec
      *info.wn_1 = wn
      *info.spec_1 = spec
      RRCAT_KK_UPDATE_PLOTS, info, 1
    END
    'FILE_2_SELECT':BEGIN
      file = dialog_pickfile(TITLE='Select File for Spectrum 2', PATH = info.directory)
      IF N_ELEMENTS(file) EQ 1 and file[0] EQ '' THEN BEGIN
        RETURN
      ENDIF
      read_spc, file, wn, spec
      *info.wn_2 = wn
      *info.spec_2 = spec
      RRCAT_KK_UPDATE_PLOTS, info, 2
    END
    'FILE_3_SELECT':BEGIN
      file = dialog_pickfile(TITLE='Select File for Spectrum 3', PATH = info.directory)
      IF N_ELEMENTS(file) EQ 1 and file[0] EQ '' THEN BEGIN
        RETURN
      ENDIF
      read_spc, file, wn, spec
      *info.wn_3 = wn
      *info.spec_3 = spec
      RRCAT_KK_UPDATE_PLOTS, info, 3
    END
    'FILE_4_SELECT':BEGIN
      file = dialog_pickfile(TITLE='Select File for Spectrum 4', PATH = info.directory)
      IF N_ELEMENTS(file) EQ 1 and file[0] EQ '' THEN BEGIN
        RETURN
      ENDIF
      read_spc, file, wn, spec
      *info.wn_4 = wn
      *info.spec_4 = spec
      RRCAT_KK_UPDATE_PLOTS, info, 4
    END
    ;    'FILE_1_COLOR':BEGIN
    ;      bg = dialog_colorpicker(TITLE='')
    ;      IF N_ELEMENTS(bg) NE 1 THEN widget_control,info.file_1_color,background_color=bg
    ;    END
    ;    'FILE_2_COLOR':BEGIN
    ;      bg = dialog_colorpicker(TITLE='')
    ;      IF N_ELEMENTS(bg) NE 1 THEN widget_control,info.file_2_color,background_color=bg
    ;    END
    ;    'FILE_3_COLOR':BEGIN
    ;      bg = dialog_colorpicker(TITLE='')
    ;      IF N_ELEMENTS(bg) NE 1 THEN widget_control,info.file_3_color,background_color=bg
    ;    END
    ;    'FILE_4_COLOR':BEGIN
    ;      bg = dialog_colorpicker(TITLE='')
    ;      IF N_ELEMENTS(bg) NE 1 THEN widget_control,info.file_4_color,background_color=bg
    ;    END
    'MIN_WN_1':BEGIN
      IF (*info.wn_1 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 1
    END
    'MIN_WN_2':BEGIN
      IF (*info.wn_2 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 2
    END
    'MIN_WN_3':BEGIN
      IF (*info.wn_3 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 3
    END
    'MIN_WN_4':BEGIN
      IF (*info.wn_4 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 4
    END
    'MAX_WN_1':BEGIN
      IF (*info.wn_1 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 1
    END
    'MAX_WN_2':BEGIN
      IF (*info.wn_2 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 2
    END
    'MAX_WN_3':BEGIN
      IF (*info.wn_3 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 3
    END
    'MAX_WN_4':BEGIN
      IF (*info.wn_4 NE !NULL) THEN RRCAT_KK_UPDATE_PLOTS, info, 4
    END
    'COMPUTE_KK':BEGIN
      widget_control,/hourglass
      dat = RRCAT_KK_STITCH_SPECTRUM(info)
      minWn = info.kk_min_wn_field->get_value()
      maxWn = info.kk_max_wn_field->get_value()
      phase = RRCAT_compute_kk_transform(dat.wn, dat.Spec, wnout, phaseLimits=[minWn, maxWn])
      *info.phas = phase
      wh = WHERE(dat.wn GE minWn AND dat.wn LE maxWn, whCount)
      *info.wn_r = dat.wn[wh]
      *info.refl = dat.Spec[wh]
      wh = WHERE(wnout GE minWn AND wnout LE maxWn, whCount)
      *info.wn_p = wnout[wh]
      *info.phas = phase[wh]
      RRCAT_KK_UPDATE_OUTPUT_PLOTS, info
      widget_control,hourglass=0
    END
    'SAVE_KK':BEGIN
      IF (*info.wn_r NE !NULL) THEN BEGIN

        wn_r = *info.wn_r
        refl = *info.refl

        outFile = dialog_pickfile(TITLE='Select Reflectance Output File', FILTER = '*.spc', PATH = info.directory)
        IF N_ELEMENTS(outFile) EQ 1 and outFile[0] EQ '' THEN BEGIN
          RETURN
        ENDIF
        IF STRLOWCASE(STRMID(outFile, 4, 4)) NE '.spc' THEN plotFile = plotFile + '.spc'
        WRITE_SPC,outFile,refl,wn_r[0],wn_r[1]-wn_r[0]
        p = plot(wn_r, refl, xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Reflectance (a.u.)', thick = 2)
        plotFile = DIALOG_PICKFILE(TITLE='Please choose a name for the plot file.', FILTER = '*.pdf', PATH = info.directory)
        IF N_ELEMENTS(plotFile) GT 0 AND plotFile[0] NE '' THEN BEGIN
          IF STRLOWCASE(STRMID(plotFile, 4, 4)) NE '.pdf' THEN plotFile = plotFile + '.pdf'
          p.save, plotFile
        ENDIF
        p.close

        wn_p = *info.wn_p
        phas = *info.phas

        outFile = dialog_pickfile(TITLE='Select Phase Output File', FILTER = '*.spc', PATH = info.directory)
        IF N_ELEMENTS(outFile) EQ 1 and outFile[0] EQ '' THEN BEGIN
          RETURN
        ENDIF
        IF STRLOWCASE(STRMID(outFile, 4, 4)) NE '.spc' THEN plotFile = plotFile + '.spc'
        WRITE_SPC,outFile,phas,wn_p[0],wn_p[1]-wn_p[0]
        p = plot(wn_p, phas, xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Phase (rad.)', thick = 2)
        plotFile = DIALOG_PICKFILE(TITLE='Please choose a name for the plot file.', FILTER = '*.pdf', PATH = info.directory)
        IF N_ELEMENTS(plotFile) GT 0 AND plotFile[0] NE '' THEN BEGIN
          IF STRLOWCASE(STRMID(plotFile, 4, 4)) NE '.pdf' THEN plotFile = plotFile + '.pdf'
          p.save, plotFile
        ENDIF
        p.close
      ENDIF
    END

    else:message,'unhandled event in top level base: '+thisEvent,/info

  ENDCASE

  Widget_Control, event.top, Set_UValue=info

END ;----------------------------------------------------------------------------

