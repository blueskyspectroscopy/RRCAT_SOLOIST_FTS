
;+
; NAME:
;	SOLOIST_FTS_ADC_INIT
;
; PURPOSE:
; This is a wrapper for the DT98** DLMs and DT7816 object so that the SOLOIST_FTS gui can work with different ADC models.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=SOLOIST_FTS_ADC_INIT()
;
; INPUTS:
;	none
;
; KEYWORD PARAMETERS:
;	MODEL:	the ADC model number, eg 'DT9803' or 'DT9804' or 'DT7816'
; OBJECT: an object reference for the ADC interface, such as DT7816. If OBJECT is defined, it is destroyed for the DT7816 model
; BUFFLEN:
; N_BUFF:
; GAIN:
; DEBUG:
; CLOCK:
; IP:
; DATA_PORT:
; COMM_PORT:
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Jul 6 2009.
;   Jul 30 2009 (BGG) - added error handler. DT9803_INIT should return error code instead of
;		 issuing error and stopping if initialization fails.
;   Aug 16 2016 (BGG) - extended for use with DT7816 object
;   02 May 2018 (TRF) - Adapted for RRCAT to all for multiple input channels
;-
;TODO- some inconsistency since the DT7816 expects an IP address.

FUNCTION RRCAT_SOLOIST_FTS_ADC_INIT, model=model, object=obj, bufflen=bufflen, n_buff=n_buff, clock_freq=clock_freq, clock_source=clock_source, IP=IP, data_port=data_port, $
  comm_port=comm_port, mc1808x_serial=mc1808x_serial, gain=gain, a_channels = a_channels, debug=debug, _extra=e

  ; Establish error handler. When errors occur, the index of the
  ; error is returned in the variable Error_status:
  CATCH, Error_status
  IF Error_status NE 0 THEN BEGIN
    ;using the continue keyword will output the error to the journal but not stop processing.
    msg=!ERROR_STATE.MSG
    MESSAGE, 'Error index: '+ STRTRIM(Error_status,2),/cont
    MESSAGE, 'Error message: '+ msg,/cont
    CATCH, /CANCEL
    RETURN, -1
  ENDIF

  IF N_ELEMENTS(model) EQ 0 THEN BEGIN
    IF OBJ_VALID(obj) THEN model=OBJ_CLASS(obj) ELSE model=''
  ENDIF

  CASE model OF
    'DT9803':BEGIN
      RETURN,DT9803_init(bufflen=bufflen, n_buff=n_buff, clock=clock_freq, gain=gain, debug=debug, _extra=e)
    END
    'DT9804':BEGIN
      RETURN,DT9804_init(bufflen=bufflen, n_buff=n_buff, clock=clock_freq, gain=gain, debug=debug, _extra=e)
    END
    'DT7816':BEGIN
      IF N_ELEMENTS(IP) EQ 0 THEN BEGIN
        MESSAGE,'IP address required for DT7816!',/cont
        RETURN,-2
      ENDIF
      IF OBJ_VALID(obj) THEN OBJ_DESTROY,obj
      ;for the DLM routines, we call:
      ;result=SOLOIST_FTS_ADC_init(bufflen=bufflen,n_buff=n_buff,gain=info.gain,debug=info.debug,model=info.adc_model,clock=freq)
      ;for the DT7816, we need:
      ;result=SOLOIST_FTS_ADC_init(bufflen=bufflen,n_buff=n_buff,model=info.adc_model,clock=freq, IP=IP, data_port=data_port, comm_port=comm_port)
      obj=OBJ_NEW('DT7816',IP, data_port=data_port, comm_port=comm_port, debug=debug)
      IF ~OBJ_VALID(obj) THEN BEGIN
        MESSAGE,'Error initializing DT7816!',/cont
        RETURN,-3
      ENDIF
      RETURN,obj->CONFIGURE(buff_len=bufflen, n_buff=n_buff, n_chan=1, clock=clock_freq, _extra=e)
      ; n_chan=n_chan, clock_freq=clock_freq, n_samples=n_samples, buff_len=buff_len, n_buff=n_buff, timeout=timeout
    END
;    'MC1808':BEGIN
;      ;Need a different object for USB1808 ADC, or just use the USB1808X object?
;    END
    'MC1808X':BEGIN
      IF OBJ_VALID(obj) THEN OBJ_DESTROY,obj
      ;TODO- option for analog input mode?
      single_ended=0
      obj=OBJ_NEW('MC1808X',MC1808X_serial, single_ended=single_ended, debug=debug)
      IF ~OBJ_VALID(obj) THEN BEGIN
        MESSAGE,'Error initializing MC1808X!',/cont
        RETURN,-4
      ENDIF
      IF N_ELEMENTS(clock_source) EQ 0 THEN clock_source=0
      IF clock_source EQ 0 THEN freq=!null ELSE freq=clock_freq
      ;Default range is bipolar 10 volts ('BIP10') other options
      ;include bipolar 5 volts ('BIP5'), unipolar 10 volts ('UNI10'), unipolar 5 volts ('UNI5').
      CASE gain OF
        1:range='BIP10'
        2:range='BIP5'
        ELSE:BEGIN
          MESSAGE,'Invalid gain for MC1808X!',/cont
          MESSAGE,'Range set to +/- 10V',/cont
          range='BIP10'
        END
      ENDCASE
      ;channel numbers start at 0
      a_ranges = STRARR(N_ELEMENTS(a_channels))
      a_ranges[*] = range

      ;print, 'Clock source:'+ STRTRIM(clock_source, 2)

      result=obj->CONFIGURE(a_channels=a_channels, a_RATE=freq, a_RANGES = a_ranges, a_extclock=~clock_source )
      ;result=obj->DaqSetTrigger(TrigSense='FALLING_EDGE')
      RETURN,result
    END
    ELSE:BEGIN
      MESSAGE,'Bad ADC model in SOLOIST_FTS_ADC_INIT',/cont
    END
  ENDCASE

  RETURN,-5

END