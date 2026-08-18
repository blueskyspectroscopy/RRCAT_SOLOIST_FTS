;+
; NAME:
;	ROUTINE_NAME
;
; PURPOSE:
;	"This function (or procedure) ..."
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	ROUTINE_NAME, Parameter1, Parameter2, Foobar
;	Result = FUNCTION_NAME(Parameter1, Parameter2, Foobar)
;	(i.e., NO KEYWORDS)
;
; INPUTS:
;	Parm1:	Describe parm1 here
;	Parm2:	Describe parm2 blah
;			blah
;			blah
;	Parm3:	Describe parm3
;			blah blah blah
;
; OPTIONAL INPUTS:
;	Parm4:	Describe parm4
;	Parm5:	Describe parm5
;
; KEYWORD PARAMETERS:
;	KEY1:	Note that the keyword is shown in ALL CAPS!
;	KEY2:	"Set this keyword to use foobar subfloatation."
;
; OUTPUTS:
;	"This function returns the foobar superflimpt version of the input array."
;
; OPTIONAL OUTPUTS:
;	Describe optional outputs here.  If the routine doesn't have any,
;	just delete this section.
;
; COMMON BLOCKS:
;	BLOCK1:	Describe any common blocks here. If there are no COMMON
;		blocks, just delete this entry.
;	BLOCK2:	Describe any other common blocks here
;
; SIDE EFFECTS:
;	Describe "side effects" here.  There aren't any?  Well, just delete
;	this entry.
;
; RESTRICTIONS:
;	Describe any "restrictions" here.  Delete this section if there are
;	no important restrictions.
;
; PROCEDURE:
;	You can describe the foobar superfloatation method being used here.
;	You might not need this section for your routine.
;
; EXAMPLE:
;
;	Create a PICKFILE widget that lets users select only files with
;	the extensions 'pro' and 'dat'.  Use the 'Select File to Read' title
;	and store the name of the selected file in the variable F.  Enter:
;
;		F = PICKFILE(/READ, FILTER = ['pro', 'dat'])
;
; MODIFICATION HISTORY:
; 	Written by:	Your name here, Date.
;	July, 1994	Any additional mods get described here.  Remember to
;			change the stuff above if you add a new keyword or
;			something!
;
;	Copyright 2007, Blue Sky Spectroscopy Inc.
; 	All rights reserved.
;-

PRO DOCUMENTATION_TEMPLATE

  PRINT, "This is an example header file for documenting IDL routines. ",$
  	"Paste all the above comments into your file, and edit as appropriate. ",$
  	"the leading + and trailing - are required. "


END

;==========================================================================
;  IDLWAVE_TEMPLATE - Demonstrate an IDL coding style, as enforced by
;                     IDLWAVE.  It can be useful to have a small
;                     header like this describing the function in
;                     files containing many routines.  Note that
;                     keywords are all uppercase, and arguments all
;                     lowercase.
;==========================================================================
function idlwave_template, foob, bloo, igoo, MARK=mark, PARM=PARM, $
                           LRAN=lran, _EXTRA=e

  ;; Main block indent, 2
  common idlwave_template, idlwave_unique_var1, idlwave_unique_var2

  ;; This is a source left-aligned comment, beginning with ;;

  ;; Variables: usually lowercase
  got_arg=n_elements(igoo) gt 0

  ;; Loops (all reserved words are lowercase)
  for i=0,12 do begin
     ;; Loop indent, 3
     print,i                    ;in line comment, single semi-colon
  endfor

  ;; Full blocks
  if bloo gt foob then begin
     igoo=4
  endif else begin
     igoo=42
  endelse

  ;; Continued bocks
  if foob gt 12 then $
     print,'Foob: Greater than 12' $
  else print,'Foob: Less than or equal to 12'

  ;; Multi-command lines
  foob=foob>12 & bloo=14 & igoo=foob>2

  ;; Continued assignments
  result1=foob + bloo^2 + 0.05*igoo + $
          sqrt(foob + igoo)

  ;; Structures, and function calls (and other aligned-parentheticals)
  result2=function_name(foob, bloo, igoo, $
                        mark, ANOTHER_KEY=12.22)

  structure={field1:1, $        ;This is the documentation for field1
             field2:[2,3,4], $  ;Field2 is also very interesting
             field3:[7,8,9]}    ;Disregard field3

  long_arr=[1, 22, 333, 4444, $
            55555, 666666, 7777777]


  ;; Long-winded routine call comments
  ans=convol(long_arr,$         ;test
                                ;initial comments
             bloo_kernel, $     ;a really long
                                ;comment is now OK

             scale_fac $        ;and we can even put in blanks
                                ;etc.
            )

  ;; Class/method calls
  obj=obj_new('MySpecialClass', 1, 2, 3) ;mixed case class
  method_result=obj->SuperClass::Compute(foob)

  ;; Long procedure names
  a_very_long_and_verbose_function_name_which_uses_up_an_entire_line, $
     igoo, arg4                 ;continuation indent: 3

  return, foob + bloo + (n_elements(igoo) gt 0?igoo:42)
end

