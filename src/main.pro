; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
;	Unauthorized reproduction prohibited without touting Darkhan's
;	name. Please help me live forever by continuing the tradition
;	of honoring science nerds of the past by putting their name in
;	your code that uses theirs. 
;
+
; NAME:
; RUN_IRAC_LIMIT
;
; PURPOSE:
; This here procedure serves as the main driver for IRAC sensitivity analysis, processing multiple targets across specified channels and flux factors to determine detection limits.
;
; CATEGORY:
; Astronomy, IRAC Data Analysis, Pipeline Processing
;
; CALLING SEQUENCE:
; RUN_IRAC_LIMIT, Config
;
; INPUTS:
; Config: The configuration file containing all processing parameters including input/output paths, flux factors, aperture parameters, and channel specifications.
;
; PROCEDURE:
; This routine reads configuration parameters and target lists, then processes each target through all specified IRAC channels and flux factors. It performs PRF placement, photometry, and sensitivity analysis, outputting results to files and generating final detection limits.
;
; EXAMPLE:
; Process a set of targets through IRAC channels 1 and 2 with varying flux factors:
;
; RUN_IRAC_LIMIT, 'config_file.txt'
;
; MODIFICATION HISTORY:
; 	Written by:	Darkhan Nurzhakyp 2025 September 30
;	September,2025	Any additional mods get described here.  Remember to
;			change the stuff above if you add a new keyword or
;			something!
;-

;-----------------------------------------------------------------
;               Mini-Routines (main routine comes last)
;-----------------------------------------------------------------

function to_array, array
  compile_opt IDL2

  clean_str = STRMID(array, 1, STRLEN(array)-2)
  parts = STRSPLIT(clean_str, ',', /EXTRACT)
  return, parts
end

;-----------------------------------------------------------------
;-----------------------------------------------------------------
;                             Main Routine
;-----------------------------------------------------------------
;-----------------------------------------------------------------

pro run_irac_limit, config
  compile_opt IDL2

  ;=====configuration=====
  readcoldat, config, conf, comchar='#'

  input_path= conf[0,0]
  output_path= conf[1,0]
  data_path= conf[2,0]
  test_path= conf[11,0]
  
  factors= to_array(conf[3,0])
  factors = FLOAT(factors)
  
  rap= FLOAT(conf[4,0])
  rbackin= FLOAT(conf[5,0])
  rbackout= FLOAT(conf[6,0])
  spacing= FLOAT(conf[7,0])
  channels= to_array(conf[10,0]) ;e.g. [1,2,3,4]

  prf_path= conf[8,0]

  readcoldat, input_path, data, comchar='#'
  
  nrows = n_elements(data) / 3
  ;======================

  ;=====intermediate results=====
  openw, unit, output_path, /get_lun
  printf, unit, '# name    ra    dec    channel    x_pos    y_pos    expected_flux    phot_flux_(µJy)    phot_sigma_(µJy)'

  openw, test_unit, test_path, /get_lun
  printf, test_unit, '# name    ra    dec    channel    x_pos    y_pos    expected_flux    phot_flux_(µJy)    phot_sigma_(µJy)    total    sig'
  
  FOR ii=0, nrows-1 DO BEGIN

     FOR jj= 0, n_elements(channels)-1 DO BEGIN
        mag_name = data[0, ii]
        ra       = data[1, ii]
        dec      = data[2, ii]

        PRINT, 'Processing ' + mag_name + ' channel ' + channels[jj]

        CATCH, err
        IF err NE 0 THEN BEGIN
           CATCH, /CANCEL
           PRINT, 'Error during irac_limit for ', mag_name, ' channel ', channels[jj]
           CONTINUE
        ENDIF
        
        FOR kk=0, n_elements(factors)-1 DO BEGIN
           irac_limit, data_path, mag_name, ra, dec, channels[jj], factors[kk], $
                       rap, rbackin, rbackout, spacing, prf_path, unit, test_unit, $
                       /phot, /test
        ENDFOR
        
        PRINT, 'Finished ' + mag_name + ' channel ' + channels[jj]
     ENDFOR

     
  ENDFOR

  close, unit
  free_lun, unit

  close, test_unit
  free_lun, test_unit

  print, 'Results written to ', output_path

  ;=======================

  ;stop

  ;=====flux at 5sigma=====
  result_path = conf[9,0]
  cmd = './darkhan_run_py.sh ' + output_path + ' ' + result_path
  spawn, cmd
  ;=======================

  stop
  
end
