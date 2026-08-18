;+
; NAME:
;	RRCAT_COMPUTE_OPTICAL_CONSTANTS_EVENT
;
; PURPOSE:
;	This is the main event handler for RRCAT_COMPUTE_OPTICAL_CONSTANTS.pro. All events are handled by this
;	code first.
;
; CATEGORY:
;	RRCAT Analysis Optical Constants
;
; CALLING SEQUENCE:
;	RRCAT_COMPUTE_OPTICAL_CONSTANTS_EVENT, Event
;
; INPUTS:
;	Event:	The widget event
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, Aug 22 2019.
;-


PRO RRCAT_COMPUTE_OPTICAL_CONSTANTS_Event, event

  Widget_Control, event.top, Get_UValue=info

  if event.id eq event.top then begin
    ;the event came from the TLB. Resize the plot object
    ysize=event.y > info.widget_min_ysize 	;limit ysize so that the buttons don't get clipped.
    xsize=event.x > info.widget_x_size*2 	;limit xsize so that the plots aren't too small.

    widget_control,event.id, xsize=xsize, ysize=ysize
    info.refl_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.n_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.refl_plot->show
    info.n_plot->show

    info.eps_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.sig_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.eps_plot->show
    info.sig_plot->show
    return
  endif

  Widget_Control, event.id, Get_UValue=thisEvent

  CASE thisEvent OF
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
    'NULL':begin	;for widgets with meaningless events.
    end
    'QUIT': begin
      Widget_Control, event.top, /Destroy
      return
    end
    'SPC Plot Event': BEGIN
      case TAG_NAMES( event, /STRUCTURE_NAME) of
        'BGPLOTEVENT' : begin

        end
        else : stop
      endcase
    END
    'R_FILE_SELECT':BEGIN
      file = dialog_pickfile(TITLE='Select File for Reflectance', PATH = info.directory)
      IF N_ELEMENTS(file) EQ 1 and file[0] EQ '' THEN BEGIN
        RETURN
      ENDIF
      read_spc, file, wn, spec
      *info.wn_r = wn
      *info.refl = spec

      IF info.refl_plot->ISCONTAINED('current') THEN BEGIN
        info.refl_plot->SETDATA,'current',*info.wn_r, *info.refl
      ENDIF ELSE BEGIN
        info.refl_plot->ADD,*info.wn_r, *info.refl,name='current'
      ENDELSE
      info.refl_plot->show
    END
    'PHASE_FILE_SELECT':BEGIN
      file = dialog_pickfile(TITLE='Select File for Phase', PATH = info.directory)
      IF N_ELEMENTS(file) EQ 1 and file[0] EQ '' THEN BEGIN
        RETURN
      ENDIF
      read_spc, file, wn, spec
      *info.wn_p = wn
      *info.phase = spec
    END
    'COMPUTE_OPTICAL_CONSTANTS':BEGIN
      wn_r = *info.wn_r
      refl = *info.refl
      wn_p = *info.wn_p
      phase = *info.phase

      ;      STOP
      wn = wn_r

      rc = RRCAT_compute_n_and_k(wn, refl, phase, n, k)
      rc = RRCAT_compute_epsilon_and_alpha(wn, n, k, epsilon, alpha, sigma)

      *info.wn = wn
      *info.n = n
      *info.epsilon = epsilon
      *info.sigma = sigma
      RRCAT_COMPUTE_OPTICAL_CONSTANTS_UPDATE_OUTPUT_PLOTS, info
    END
    'SAVE_ALL':BEGIN
      IF (*info.n NE !NULL) THEN BEGIN
        wn = *info.wn
        n = *info.n
        epsilon = *info.epsilon
        sigma = *info.sigma

        outFile = dialog_pickfile(TITLE='Select Refractive Index Output File', FILTER = '*.spc', PATH = info.directory)
        IF N_ELEMENTS(outFile) EQ 1 and outFile[0] EQ '' THEN BEGIN
          RETURN
        ENDIF
        IF STRLOWCASE(STRMID(outFile, 4, 4)) NE '.spc' THEN plotFile = plotFile + '.spc'
        WRITE_SPC,outFile,n,wn[0],wn[1]-wn[0]
        p = plot(wn, n, xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Refractive Index (a.u.)', thick = 2)
        plotFile = DIALOG_PICKFILE(TITLE='Please choose a name for the plot file.', FILTER = '*.pdf', PATH = info.directory)
        IF N_ELEMENTS(plotFile) GT 0 AND plotFile[0] NE '' THEN BEGIN
          IF STRLOWCASE(STRMID(plotFile, 4, 4)) NE '.pdf' THEN plotFile = plotFile + '.pdf'
          p.save, plotFile
        ENDIF
        p.close

        outFile = dialog_pickfile(TITLE='Select Dielctric Constant Output File', FILTER = '*.spc', PATH = info.directory)
        IF N_ELEMENTS(outFile) EQ 1 and outFile[0] EQ '' THEN BEGIN
          RETURN
        ENDIF
        IF STRLOWCASE(STRMID(outFile, 4, 4)) NE '.spc' THEN plotFile = plotFile + '.spc'
        WRITE_SPC,outFile,epsilon,wn[0],wn[1]-wn[0]
        p = plot(wn, epsilon, xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Dielctric Constant (a.u.)', thick = 2)
        plotFile = DIALOG_PICKFILE(TITLE='Please choose a name for the plot file.', FILTER = '*.pdf', PATH = info.directory)
        IF N_ELEMENTS(plotFile) GT 0 AND plotFile[0] NE '' THEN BEGIN
          IF STRLOWCASE(STRMID(plotFile, 4, 4)) NE '.pdf' THEN plotFile = plotFile + '.pdf'
          p.save, plotFile
        ENDIF
        p.close

        outFile = dialog_pickfile(TITLE='Select Optical Conductivity Output File', FILTER = '*.spc', PATH = info.directory)
        IF N_ELEMENTS(outFile) EQ 1 and outFile[0] EQ '' THEN BEGIN
          RETURN
        ENDIF
        IF STRLOWCASE(STRMID(outFile, 4, 4)) NE '.spc' THEN plotFile = plotFile + '.spc'
        WRITE_SPC,outFile,sigma,wn[0],wn[1]-wn[0]
        p = plot(wn, sigma, xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Optical Conductivity (a.u.)', thick = 2)
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

