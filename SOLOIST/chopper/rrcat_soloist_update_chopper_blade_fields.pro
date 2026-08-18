;+
; NAME:
; RRCAT_SOLOIST_UPDATE_CHOPPER_BLADE_FIELDS
;
; PURPOSE:
; This procedure modifies the RRCAT SOLOIST GUI so that the
; proper chopper output and reference options are displayed
; when a given blade is selected.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_soloist_update_chopper_blade_fields, info, blade
;
; INPUTS:
; info: The main info structure
; blade: The selected blade number
;
; KEYWORDS:
;
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 26 2018.
;-
PRO rrcat_soloist_update_chopper_blade_fields, info, blade

  CASE blade OF
;    0: BEGIN
;      chop_outputs = ['Target', 'Actual']
;      chop_references = ['Internal', 'External']
;    END
;    1: BEGIN
;      chop_outputs = ['Target', 'Outer', 'Inner']
;      chop_references = ['INT Outer', 'INT Inner', 'EXT Outer', 'EXT Inner']
;    END
;
    0: BEGIN
      chop_outputs = ['Target', 'Outer', 'Inner']
      chop_references = ['INT Outer', 'INT Inner', 'EXT Outer', 'EXT Inner']
    END
    1: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    2: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    3: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    4: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    5: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    6: BEGIN
      chop_outputs = ['Target', 'Outer', 'Inner']
      chop_references = ['INT Outer', 'INT Inner', 'EXT Outer', 'EXT Inner']
    END
    7: BEGIN
      chop_outputs = ['Target', 'Outer', 'Inner']
      chop_references = ['INT Outer', 'INT Inner', 'EXT Outer', 'EXT Inner']
    END
    8: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    9: BEGIN
      chop_outputs = ['Target', 'Actual']
      chop_references = ['Internal', 'External']
    END
    10: BEGIN
      chop_outputs = ['Outer', 'Inner', 'Sum', 'Diff']
      chop_references = ['Internal', 'External']
    END
    11: BEGIN
      chop_outputs = ['Outer', 'Inner', 'Sum', 'Diff']
      chop_references = ['Internal', 'External']
    END
    12: BEGIN
      chop_outputs = ['Outer', 'Inner', 'Sum', 'Diff']
      chop_references = ['Internal', 'External']
    END
    13: BEGIN
      chop_outputs = ['Outer', 'Inner', 'Sum', 'Diff']
      chop_references = ['Internal', 'External']
    END
    14: BEGIN
      chop_outputs = ['Outer', 'Inner', 'Sum', 'Diff']
      chop_references = ['Internal', 'External']
    END
  ENDCASE
  ;STOP
  WIDGET_CONTROL, info.output_select_chop, /DESTROY
  WIDGET_CONTROL, info.ref_select_chop, /DESTROY
  info.output_select_chop = CW_BGROUP(info.output_select_base, chop_outputs, SET_VALUE=0, LABEL_LEFT='Output', /EXCLUSIVE, $
    uvalue='CHOPPER_OUTPUT', /no_release)
  info.ref_select_chop=CW_BGROUP(info.ref_select_base, chop_references, SET_VALUE=0, LABEL_LEFT='Reference', /EXCLUSIVE, $
    uvalue='CHOPPER_REFERENCE', /no_release, /col)
END