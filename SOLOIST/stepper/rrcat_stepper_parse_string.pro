;+
; NAME:
; RRCAT_STEPPER_PARSE_STRING
;
; PURPOSE:
; This function parses the string returned by the stepper motor controller
; to a more digestible form.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; struct = RRCAT_STEPPER_PARSE_STRING(str, info)
;
; INPUTS:
; str: The string to be parsed.
; info:  the main info block structure.
;
; KEYWORDS:
; LIMITSTATE: If set, the string is in response to a limit state query.
; STATUS: If set, the string is in response to a status query.
; LATCH: If set, the string is in response to a latch query.
; MOTORSTATE: If set, the string is in response to a motor state query.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018.
;   04 July 2019 (TRF): Print limit state information to the GUI console
;   19 Sept 2019 (TRF): FTS Selection mirror is now M4 instead of M5
;                       Bit masks for index 3 of the motorStruct array 
;                       need to be adjusted accordingly.
;-

function rrcat_stepper_parse_string, str, info, LIMITSTATE=LIMITSTATE, STATUS=STATUS, LATCH=LATCH, MOTORSTATE=MOTORSTATE, debug=debug, stepperMotors=stepperMotors
  CATCH, theError
  if theError NE 0 then begin
    message, !ERROR_STATE.msg, /cont
    ;x=self->close()
    CATCH, /CANCEL
    info.simStepper = 1
    ; TODO Replace with a DIALOG_MESSAGE popup
    SOLOIST_FTS_MESSAGE, info, 'Error communicating with Stepper Controller. Reset its connection.'
    return, str
  endif

  IF NOT KEYWORD_SET(debug) THEN debug = 0
  IF str EQ '-1' THEN return, str
  IF N_ELEMENTS(info) NE 0 THEN BEGIN
    stepperMotors = info.stepperMotors
  ENDIF ELSE BEGIN
    IF N_ELEMENTS(stepperMotors) EQ 0 THEN BEGIN
      stepperMotors = REPLICATE({rrcat_motor_struct}, 5)
      foreach motorStr, stepperMotors, index do begin
        motorStr.motor = index
        IF index GT 2 THEN motorStr.motor = index+1
        ;motorStr.async = 1
        stepperMotors[index] = motorStr
      endforeach
    ENDIF
  ENDELSE
  bData = BYTE(str)
  ;
  ; TODO: Check that bData is not null
  ;
  ;
  ; Remove the last three characters
  ;
  bData = bData[0:N_ELEMENTS(bData)-1 - 3]
  ;
  ; Some return strings start with \cr\cr\lf
  ; others with \cr\lf. Check the fist few characters and remove up to the first \lf
  ;
  wh = WHERE(bData EQ 10, whCount)
  IF whCount NE 0 THEN bData = bData[wh[0]+1:N_ELEMENTS(bData)-1]
  ;
  ; Replace any CR+LF combinations with a comma
  ;
  wh = WHERE(bData EQ 13, whCount)
  IF whCount GT 0 THEN BEGIN
    FOREACH ind, wh DO BEGIN
      IF ind+1 LT N_ELEMENTS(bData) AND bData[ind+1] EQ 10 THEN BEGIN
        bData[ind] = 44
      ENDIF
    ENDFOREACH
    wh = WHERE(bData EQ 10, whCount, COMPLEMENT= nwh, NCOMPLEMENT = nwhCount)
    IF nwhCount GT 0 THEN bData = bData[nwh]
  ENDIF
  ;
  ; Remove any remaining CRs and the trailing asterisk (should not be any left though)
  ;
  wh = WHERE(bData EQ 13, whCount, COMPLEMENT= nwh, NCOMPLEMENT = nwhCount)
  IF nwhCount GT 0 THEN bData = bData[nwh]
  wh = WHERE(bData EQ 42, whCount, COMPLEMENT= nwh, NCOMPLEMENT = nwhCount)
  IF nwhCount GT 0 THEN bData = bData[nwh]

  newStr = STRING(bData)
  ;
  ; Now parse out the information for each motor and populate its rrcat_motor_struct
  ;
  strSplt = STRSPLIT(newStr, ',', /EXTRACT)
  IF KEYWORD_SET(STATUS) THEN BEGIN
    command = '0'
    foreach motorStruct, stepperMotors, index do begin
      thisMotor = motorStruct.motor
      motorStr = rrcat_get_motor_string(thisMotor)
      wh = WHERE(strSplt EQ 'M'+motorStr)
      motorStruct.location = LONG(strSplt[wh+2])
      motorStruct.speed = FIX(strSplt[wh+11])
      ;motorStruct.accel = FIX(strSplt[wh+4])
      motorStruct.windingsState = FIX(strSplt[wh+7])
      motorStruct.windingsStateStop = FIX(strSplt[wh+8])
      motorStruct.state = FIX(strSplt[wh+9])
      motorStruct.stepStyle = FIX(strSplt[wh+10])
      stepperMotors[index] = motorStruct
    endforeach
    if debug GT 0 THEN BEGIN
      str = $
        'Motor W, Location:'+STRTRIM(stepperMotors[0].location, 2) + ' Speed:'+STRTRIM(stepperMotors[0].speed, 2)+ ' Idle:'+STRTRIM(stepperMotors[0].windingsStateStop, 2)+string([13B, 10B]) + $
        'Motor X, Location:'+STRTRIM(stepperMotors[1].location, 2) + ' Speed:'+STRTRIM(stepperMotors[1].speed, 2)+ ' Idle:'+STRTRIM(stepperMotors[1].windingsStateStop, 2)+string([13B, 10B]) + $
        'Motor Y, Location:'+STRTRIM(stepperMotors[2].location, 2) + ' Speed:'+STRTRIM(stepperMotors[2].speed, 2)+ ' Idle:'+STRTRIM(stepperMotors[2].windingsStateStop, 2)+string([13B, 10B]) + $
        ;'Motor Z, Location:'+STRTRIM(stepperMotors[3].location, 2) + ' Speed:'+STRTRIM(stepperMotors[3].speed, 2)+'\n' + ' Idle:'+STRTRIM(stepperMotors[3].windingsStateStop, 2)+'\n' + $
        'Motor A, Location:'+STRTRIM(stepperMotors[3].location, 2) + ' Speed:'+STRTRIM(stepperMotors[3].speed, 2)+ ' Idle:'+STRTRIM(stepperMotors[3].windingsStateStop, 2)+string([13B, 10B]) + $
        'Motor B, Location:'+STRTRIM(stepperMotors[4].location, 2) + ' Speed:'+STRTRIM(stepperMotors[4].speed, 2)+ ' Idle:'+STRTRIM(stepperMotors[4].windingsStateStop, 2)+string([13B, 10B])
    endif
  ENDIF


  IF KEYWORD_SET(LIMITSTATE) THEN BEGIN
    command = '6'
    limit = LONG(strSplt[2])
    stepperMotors[0].limitminus = ((limit AND 1) GT 0) ? 0 : 1
    stepperMotors[0].limitplus = ((limit AND 2) GT 0) ? 0 : 1
    stepperMotors[1].limitminus = ((limit AND 4) GT 0) ? 0 : 1
    stepperMotors[1].limitplus = ((limit AND 8) GT 0) ? 0 : 1
    stepperMotors[2].limitminus = ((limit AND 16) GT 0) ? 0 : 1
    stepperMotors[2].limitplus = ((limit AND 32) GT 0) ? 0 : 1
        stepperMotors[3].limitminus = ((limit AND 64) GT 0) ? 0 : 1
        stepperMotors[3].limitplus = ((limit AND 128) GT 0) ? 0 : 1
;    stepperMotors[3].limitminus = ((limit AND 256) GT 0) ? 0 : 1
;    stepperMotors[3].limitplus = ((limit AND 512) GT 0) ? 0 : 1
    stepperMotors[4].limitminus = ((limit AND 1024) GT 0) ? 0 : 1
    stepperMotors[4].limitplus = ((limit AND 2048) GT 0) ? 0 : 1
    if debug GT 0 THEN BEGIN
      ;SOLOIST_FTS_MESSAGE, info, str
      ;print, str
      str = $
        'Motor W, Limit-:'+STRTRIM(stepperMotors[0].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[0].limitplus, 2)+string([13B, 10B]) + $
        'Motor X, Limit-:'+STRTRIM(stepperMotors[1].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[1].limitplus, 2)+string([13B, 10B])+ $
        'Motor Y, Limit-:'+STRTRIM(stepperMotors[2].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[2].limitplus, 2)+string([13B, 10B])+ $
        ;        'Motor Z, Limit-:'+STRTRIM(stepperMotors[3].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[3].limitplus, 2)+'\n' + $
        'Motor A, Limit-:'+STRTRIM(stepperMotors[3].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[3].limitplus, 2)+string([13B, 10B])+ $
        'Motor B, Limit-:'+STRTRIM(stepperMotors[4].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[4].limitplus, 2)+string([13B, 10B])
      ;print, str
      ;SOLOIST_FTS_MESSAGE, info, str
    endif
  ENDIF

  IF KEYWORD_SET(LATCH) THEN BEGIN
    command = 'L'
    latchVal = LONG(strSplt[1])
    stepperMotors[0].limitminus = ((latchVal AND 1) GT 0) ? 0 : 1
    stepperMotors[0].limitplus = ((latchVal AND 2) GT 0) ? 0 : 1
    stepperMotors[0].fault = ((latchVal AND 16777216) GT 0) ? 0 : 1
    stepperMotors[1].limitminus = ((latchVal AND 4) GT 0) ? 0 : 1
    stepperMotors[1].limitplus = ((latchVal AND 8) GT 0) ? 0 : 1
    stepperMotors[1].fault = ((latchVal AND 33554432) GT 0) ? 0 : 1
    stepperMotors[2].limitminus = ((latchVal AND 16) GT 0) ? 0 : 1
    stepperMotors[2].limitplus = ((latchVal AND 32) GT 0) ? 0 : 1
    stepperMotors[2].fault = ((latchVal AND 67108864) GT 0) ? 0 : 1
        stepperMotors[3].limitminus = ((latchVal AND 64) GT 0) ? 0 : 1
        stepperMotors[3].limitplus = ((latchVal AND 128) GT 0) ? 0 : 1
        stepperMotors[3].fault = ((latchVal AND 134217728) GT 0) ? 0 : 1
;    stepperMotors[3].limitminus = ((latchVal AND 256) GT 0) ? 0 : 1
;    stepperMotors[3].limitplus = ((latchVal AND 512) GT 0) ? 0 : 1
;    stepperMotors[3].fault = ((latchVal AND 268435456) GT 0) ? 0 : 1
    stepperMotors[4].limitminus = ((latchVal AND 1024) GT 0) ? 0 : 1
    stepperMotors[4].limitplus = ((latchVal AND 2048) GT 0) ? 0 : 1
    stepperMotors[4].fault = ((latchVal AND 536870912) GT 0) ? 0 : 1
    IF debug GT 0 THEN BEGIN
      str = $
        'Motor W, Limit-:'+STRTRIM(stepperMotors[0].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[0].limitplus, 2)+string([13B, 10B])+ $
        'Motor X, Limit-:'+STRTRIM(stepperMotors[1].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[1].limitplus, 2)+string([13B, 10B])+ $
        'Motor Y, Limit-:'+STRTRIM(stepperMotors[2].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[2].limitplus, 2)+string([13B, 10B])+ $
        ;'Motor Z, Limit-:'+STRTRIM(stepperMotors[3].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[3].limitplus, 2)+'\n' + $
        'Motor A, Limit-:'+STRTRIM(stepperMotors[3].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[3].limitplus, 2)+string([13B, 10B])+ $
        'Motor B, Limit-:'+STRTRIM(stepperMotors[4].limitminus, 2) + ' Limit+:'+STRTRIM(stepperMotors[4].limitplus, 2)+string([13B, 10B])
    endif
  ENDIF

  IF KEYWORD_SET(MOTORSTATE) THEN BEGIN
    command = '-8'
    foreach motorStruct, stepperMotors, index do begin
      thisMotor = motorStruct.motor
      motorStr = rrcat_get_motor_string(thisMotor)
      wh = WHERE(strSplt EQ 'M'+motorStr)
      motorStruct.state = FIX(strSplt[wh+2])
      stepperMotors[index] = motorStruct
      IF KEYWORD_SET(debug) THEN BEGIN
        str = $
          'Motor W:'+STRTRIM(stepperMotors[0].state, 2) + string([13B, 10B]) +$
          'Motor X:'+STRTRIM(stepperMotors[1].state, 2) + string([13B, 10B]) +$
          'Motor Y:'+STRTRIM(stepperMotors[2].state, 2) + string([13B, 10B]) +$
          ;          'Motor Z:'+STRTRIM(stepperMotors[3].state, 2) + '\n' +$
          'Motor A:'+STRTRIM(stepperMotors[3].state, 2) + string([13B, 10B]) +$
          'Motor B:'+STRTRIM(stepperMotors[4].state, 2) + string([13B, 10B])
      ENDIF
    endforeach
  ENDIF
  IF N_ELEMENTS(info) NE 0 THEN BEGIN
    info.stepperMotors = stepperMotors
  ENDIF
;  limitMinus = stepperMotors.limitMinus
;  print, n_elements(limitMinus)
;;  print, stepperMotors.limitMinus
;  print, stepperMotors.limitPlus
  RETURN, str
end