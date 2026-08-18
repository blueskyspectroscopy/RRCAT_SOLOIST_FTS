
;+
; NAME:
;	SOLOIST_FTS_ADC_DUMP
;
; PURPOSE:
; This is a wrapper for the DT98** DLMs and DT7816 object so that the SOLOIST_FTS gui can work with different ADC models.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=SOLOIST_FTS_ADC_DUMP()
;
; INPUTS: none
;
; KEYWORD PARAMETERS:
;	MODEL:	the ADC model number, eg 'DT9803' or 'DT9804'
; OBJECT: an object reference for the ADC interface, such as DT7816. If OBJECT is defined, MODEL is ignored
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Jul 6 2009.
;   Aug 16 2016 (BGG) - extended for use with DT7816 object
;   Aug 23 2017 (BGG) - extended for use with MC1808X object
;
;   TODO: should change to return !null on error.
;
;-
function rrcat_soloist_fts_adc_dump,model=model, object=obj, error=err
  err=''

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
      return,DT9803_dump()
    end
    'DT9804':begin
      return,DT9804_dump()
    end
    'DT7816':begin
      if obj_valid(obj) then begin
        case 1 of
          obj_isa(obj, 'DT7816'): begin
            if obj->ready() eq 0 then return,!null    ;dump will issue an error if no points are ready..
            return,obj->dump(err=err)
          end
          else: begin
            message,'Unrecognized ADC object!',/cont
          end
        endcase
        return,-1
      endif
    end
    'MC1808X':begin
      if obj_valid(obj) then begin
        case 1 of
          obj_isa(obj, 'MC1808X'): begin
            result=obj->ready('AI', Status=status, CurCount=count, CurIndex=index)
            ;if status eq 0 then return,!null    ;no acquisition in process
            if n_elements(result) eq 0 then begin
              message,'Error checking MC1808X ready!',/cont
              return,!null    ;dump will issue an error if no points are ready..
            endif
            ;if index eq 0 then return,!null ;no data
            return,obj->dump('AI')
          end
          else: begin
            message,'Unrecognized ADC object!',/cont
          end
        endcase
        return,-1
      endif
    end
    else:begin
      message,'Bad ADC model in SOLOIST_FTS_ADC_DUMP',/cont
    end
  endcase

  return,-1

end