function to_array, array
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
  bgnd = [1./10.]
  ;======================

  ;=====intermediate results=====
  openw, unit, output_path, /get_lun
  printf, unit, '# name    ra    dec    channel    x_pos    y_pos    flux_scale_factor    flux_(µJy)    sigma_(µJy)'

  openw, test_unit, test_path, /get_lun
  printf, test_unit, '# name    ra    dec    channel    x_pos    y_pos    flux_scale_factor    flux_(µJy)    sigma_(µJy)'
  
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
        
        FOR bgnd_factor=0,0 DO BEGIN
           irac_limit, data_path, mag_name, ra, dec, channels[jj], factors, $
                       rap, rbackin, rbackout, spacing, prf_path, unit, test_unit, 10.*bgnd[bgnd_factor], $
                       /norm, /verbose, /test
        ENDFOR
        
        PRINT, 'Finished ' + mag_name + ' channel ' + channel
     ENDFOR

     
  ENDFOR

  close, unit
  free_lun, unit

  close, test_unit
  free_lun, test_unit

  print, 'Results written to ', output_path

  ;=======================

  stop

  ;=====flux at 5sigma=====
  result_path = conf[9,0]
  cmd = './darkhan_run_py.sh ' + output_path + ' ' + result_path
  spawn, cmd
  ;=======================

  stop
  
end
