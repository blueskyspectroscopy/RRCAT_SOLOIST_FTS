;+
; NAME:
;	rrcat_soloist_fts_housekeeping
;
; PURPOSE:
;	This procedure reads the housekeeping from the ADC and
;	updates the housekeeping fields in the GUI. A housekeeping
;	structure is returned by this function.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	rrcat_soloist_fts_housekeeping, Info
;
; INPUTS:
;	Info:	The main info block.
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Dec 14 2017.
; 	03 May 2018 (TRF): Modified so that init is not called each time.
;   12 Jun 2019 (TRF): Added temperature and pressure conversions.
;   30 Jul 2019 (TRF): Added detector temperature
;   30 Jul 2019 (TRF): Added timing diagnostics
;   29 Aug 2019 (TRF): Removed tic()/toc() calls that were used to find cause of slowdown 
;   
;-
function rrcat_soloist_fts_housekeeping, info, simHK=simHK, simADC=simADC, NO_SAI=NO_SAI
;  IF info.debug THEN clock=tic('HK ADC')
  hk_struct = { $
    fts_temp_1:0.,$
    fts_temp_2:0.,$
    fts_pressure:0.,$
    ;    det_temp_1:0.,$
    ;    det_temp_2:0.,$
    ;    det_temp_3:0.,$
    det_pressure:0.,$
    det_temp:0.}
    
  IF KEYWORD_SET(simHK) OR KEYWORD_SET(simADC) THEN BEGIN
    hk_struct.fts_temp_1 = RANDOMN(seed)
    hk_struct.fts_temp_2 = RANDOMN(seed)
    hk_struct.fts_pressure = RANDOMN(seed)
    ;    hk_struct.det_temp_1 = RANDOMN(seed)
    ;    hk_struct.det_temp_2 = RANDOMN(seed)
    ;    hk_struct.det_temp_3 = RANDOMN(seed)
    hk_struct.det_pressure = RANDOMN(seed)
    hk_struct.det_temp = RANDOMN(seed)
    info.housekeeping = hk_struct
    RRCAT_SOLOIST_FTS_update_hk_status,info
    RETURN, hk_struct
  ENDIF

  Samples_per_channel = 64
  Rate                = 512
  clock_source = 1
  clock_freq = Rate
  ;  info.clock_source = 1
  ;  info.clock_freq = Rate
  ;result=RRCAT_SOLOIST_FTS_INIT_ADC(info)
  ;if result ne 1 then begin
  ;  SOLOIST_FTS_MESSAGE,info,'ADC acquisition failed: '+strtrim(result,2)
  ;  SOLOIST_FTS_MESSAGE,info,'ADC status: '+strtrim(SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj),2)
  ;  ;result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
  ;  RETURN, hk_struct
  ;endif
  Channel_array       = [0, 1, 2, 3, 4, 5, 6, 7]                      ; channel array must Must not have any missing
  Range_array       = ['BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10'];, 'UNI10']
  ; channels in range. i.e: [2,4,1] will cause an
  ; error since channel 3 is not included.
  ;Samples_per_channel = 100
  ;Rate                = 500

  model=info.adc_model
  obj=info.adc_obj
  ;  case model of
  ;    'DT9803':begin
  ;      return,DT9803_dump()
  ;    end
  ;    'DT9804':begin
  ;      return,DT9804_dump()
  ;    end
  ;    'DT7816':begin
  ;      if obj_valid(obj) then begin
  ;        case 1 of
  ;          obj_isa(obj, 'DT7816'): begin
  ;            if obj->ready() eq 0 then return,!null    ;dump will issue an error if no points are ready..
  ;            return,obj->dump(err=err)
  ;          end
  ;          else: begin
  ;            message,'Unrecognized ADC object!',/cont
  ;          end
  ;        endcase
  ;        return,-1
  ;      endif
  ;    end
  ;    'MC1808X':begin
  ;      if obj_valid(obj) then begin
  ;        case 1 of
  ;          obj_isa(obj, 'MC1808X'): begin
  ;            result=obj->ready('AI', Status=status, CurCount=count, CurIndex=index)
  ;            ;if status eq 0 then return,!null    ;no acquisition in process
  ;            if n_elements(result) eq 0 then begin
  ;              message,'Error checking MC1808X ready!',/cont
  ;              return,!null    ;dump will issue an error if no points are ready..
  ;            endif
  ;            if index eq 0 then return,!null ;no data
  ;            return,obj->dump('AI')
  ;          end
  ;          else: begin
  ;            message,'Unrecognized ADC object!',/cont
  ;          end
  ;        endcase
  ;        return,-1
  ;      endif
  ;    end
  ;    else:begin
  ;      message,'Bad ADC model in SOLOIST_FTS_ADC_DUMP',/cont
  ;    end
  ;  endcase
  if obj_valid(obj) then begin
    result=obj->CONFIGURE(a_channels=a_channels, a_RATE=clock_freq, a_RANGES = a_ranges, a_extclock=~clock_source )
    stat   = obj->Ain( Samples_per_channel, channels=Channel_array, Ranges=Range_array, rate=RATE)
    status = 1
    ; The program could be doing useful things here while the scan is in progress.
    while ( status ) do begin       ; could any number of conditions
      ;stop
      stat = obj->ready( 'AI', status = status, $
        CurCount = count)            ; result indicates whether scan in progress.
      ; count indicates the number of samples that have
      ; been acquired. The maximum value of count is
      ; (2^31 - 1) before it rolls back. status = 0 if idle
      ; 1 if running.

      if stat ne 1 then begin
        stat  = obj->stop( 'AI' )        ; stop background scan
        obj_destroy, obj                               ; destroys object and calls cleanup method which
        ; releases the DAQ and clears any buffers that
        ; have been allocated. The object will have printed
        ; errors that have occured.
        return, hk_struct
      endif
      wait, .05
    endwhile
    data = obj->dump( 'AI' )             ; Dump returns all data since beginning of scan.
    ;help, data
    ; Keyword necessary so we know which process to return.

    if ISA(data, /NULL) then return, hk_struct       ; Check to see if data is NULL.

    ;    hk_struct.fts_temp_1   = MEAN(data[*,1])
    ;    hk_struct.fts_temp_2   = MEAN(data[*,2])
    ;    hk_struct.fts_pressure = MEAN(data[*,3])
    ;    hk_struct.det_temp_1   = MEAN(data[*,4])
    ;    hk_struct.det_temp_2   = MEAN(data[*,5])
    ;    hk_struct.det_temp_3   = MEAN(data[*,6])
    ;    hk_struct.det_pressure = MEAN(data[*,7])

    hk_struct.fts_temp_1   = convertFtsThermometry(MEAN(data[*,3]))
    hk_struct.fts_temp_2   = convertFtsThermometry(MEAN(data[*,4]))
    hk_struct.fts_pressure = volts2torr(MEAN(data[*,5]))
    hk_struct.det_pressure = volts2torr(MEAN(data[*,6]))
    hk_struct.det_temp = (rrcat_thermometer(MEAN(data[*,7])))

    ;SOLOIST_FTS_MESSAGE,info,'HK acquisition success'
  endif
  info.housekeeping = hk_struct

  ;  info.clock_source = clock_source
  ;  info.clock_freq = clock_freq
  result = RRCAT_SOLOIST_FTS_INIT_ADC(info)
  if result ne 1 then begin
    SOLOIST_FTS_MESSAGE,info,'ADC init failed: '+strtrim(result,2)
    SOLOIST_FTS_MESSAGE,info,'ADC status: '+strtrim(SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj),2)
  endif
;  IF info.debug THEN TOC, clock
  RRCAT_SOLOIST_FTS_update_hk_status,info, NO_SAI=NO_SAI
  return, hk_struct

end



