
;+
; NAME:
;	SOLOIST_FTS_ADC_DOUT
;
; PURPOSE:
; This is a wrapper for the DT98** DLMs and DT7816 and MC1808 objects so that the 
; SOLOIST_FTS gui can work with different ADC models.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=RRCAT_SOLOIST_FTS_ADC_DOUT(val)
;
; INPUTS:
;	val - the binary value to write
;
; KEYWORD PARAMETERS:
; BITNUM: A keyword for the MC1808 ADC to allow control of a specific DIO line 
;	MODEL:	the ADC model number, eg 'DT9803' or 'DT9804'
; OBJECT: an object reference for the ADC interface, such as DT7816. If OBJECT is defined, MODEL is ignored
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Jul 6 2009.
;   Apr 16 2018 (TRF) - Modified version of SOLOIST_FTS_ADC_DOUT as the original did not have 
;                       a function for the MC1808.
;-


function rrcat_soloist_fts_adc_dout,val, model=model, object=obj

  ; Establish error handler. When errors occur, the index of the
  ; error is returned in the variable Error_status:
  CATCH, Error_status
  IF Error_status NE 0 THEN BEGIN
    ;using the continue keyword will output the error to the journal but not stop processing.
    msg=!ERROR_STATE.MSG
    message, 'Error index: '+ strtrim(Error_status,2),/cont
    message, 'Error message: '+ msg,/cont
    CATCH, /CANCEL
    return, -1
  ENDIF

  if n_elements(model) eq 0 then begin
    if obj_valid(obj) then model=obj_class(obj) else model=''
  endif

  case model of
    'DT9803':begin
      return,DT9803_dout(val)
    end
    'DT9804':begin
      return,DT9804_dout(val)
    end
    'DT7816':begin
      if obj_valid(obj) then begin
        case 1 of
          obj_isa(obj, 'DT7816'): begin
            return,obj->dout(val)
          end
          else: begin
            message,'Unrecognized ADC object!',/cont
          end
        endcase
        return,-1
      endif
    end
    'MC1808X':begin
      if obj_isa(obj, 'MC1808X') then begin
        ;help, obj
        ; TODO: Bit zero is hardcoded here.
        result=obj->dout(val)
        return,result
      endif else begin
        message,'Unrecognized ADC object!',/cont
      endelse
    end
    else:begin
      message,'Bad ADC model in RRCAT_SOLOIST_FTS_ADC_DOUT',/cont
    end
  endcase

  return,-1

end