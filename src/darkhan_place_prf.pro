;=================================================================
;  Main Routine: place_prf
;-----------------------------------------------------------------
;  Inserts a Point Response Function (PRF) into an image at the
;  specified coordinates with fractional pixel offsets.
;
;  Parameters:
;    im            - Input image
;    channel       - Channel number (1–4)
;    x0, y0        - Target coordinates (pixels)
;    xoff_fracpix  - X fractional pixel offset
;    yoff_fracpix  - Y fractional pixel offset
;    prf           - Input PRF image
;    imout         - Output image with PRF inserted
;    /VERBOSE      - Optional keyword for diagnostic printing
;=================================================================

pro place_prf, im, channel, x0, y0, xoff_fracpix, yoff_fracpix, prf, scale_factor, imout, VERBOSE=verbose

  ;---------------------------------------------------------------
  ; Channel-specific PRF scaling factors
  ;---------------------------------------------------------------
  CASE FIX(channel) OF
     1: p_prf = 1.221
     2: p_prf = 1.213
     3: p_prf = 1.222
     4: p_prf = 1.220
     ELSE: RETURN
  ENDCASE
  ; Convert to relative scale
  p_prf    = p_prf / 100.0
  p_mosaic = 0.6
  s        = p_prf / p_mosaic

  ;---------------------------------------------------------------
  ; Get PRF dimensions
  ;---------------------------------------------------------------
  prf_dim   = size(prf)
  prf_xsize = prf_dim[1]
  prf_ysize = prf_dim[2]

  ; Locate maximum in original PRF
  mx = MAX(prf, I)
  cx_prf = I MOD prf_xsize
  cy_prf = I / prf_ysize

  if keyword_set(verbose) then begin
    print, "=====PLACE_PRF====="
    print, "Original PRF max value: ", mx
    print, "Original PRF max coords: ", STRTRIM(cx_prf,1), ",", STRTRIM(cy_prf,1)
  endif

  ;---------------------------------------------------------------
  ; Trim 50-pixel borders of zeros
  ;---------------------------------------------------------------
  prf_trimmed = prf[50:prf_xsize-51, 50:prf_ysize-51]

  mx = MAX(prf_trimmed, I)
  dim = size(prf_trimmed)
  cx_prf_trim = I MOD dim[1]
  cy_prf_trim = I / dim[2]

  if keyword_set(verbose) then begin
    print, "Trimmed PRF max value: ", mx
    print, "Trimmed PRF max coords: ", cx_prf_trim, ",", cy_prf_trim
  endif

  ;---------------------------------------------------------------
  ; Compute new dimensions (ensure odd sizes for symmetry)
  ;---------------------------------------------------------------
  IF (channel EQ 1) OR (channel EQ 3) THEN BEGIN
    new_xsize = ceil(dim[1] * s)  ; even → ceil → odd
    new_ysize = ceil(dim[2] * s)
  ENDIF ELSE IF (channel EQ 2) OR (channel EQ 4) THEN BEGIN
    new_xsize = floor(dim[1] * s) ; odd → floor → odd
    new_ysize = floor(dim[2] * s)
  ENDIF ELSE RETURN

  ;---------------------------------------------------------------
  ; Apply sub-pixel shift before scaling
  ;---------------------------------------------------------------
  prf_shifted = prf_trimmed * 0.0
  max = dim[1] - 1

  shift_x = fix(xoff_fracpix / s)
  shift_y = fix(yoff_fracpix / s)

  prf_shifted[0:max-shift_x, 0:max-shift_y] = $
    prf_trimmed[shift_x:max, shift_y:max]

  ;---------------------------------------------------------------
  ; Rescale PRF using interpolation
  ;---------------------------------------------------------------
  prf_scaled = CONGRID(prf_shifted, new_xsize, new_ysize, /interp)
  if keyword_set(verbose) then begin
     print, 'PRF_shifted total= ', total(prf_shifted)
     print, 'PRF after CONGRID total= ', total(prf_scaled)
     sc = size(prf_scaled)
     print, "Max after CONGRID: ", MAX(prf_scaled, I)
     print, "Scaled PRF max coords: ", I MOD sc[1], ",", I / sc[2]
  endif

  ;---------------------------------------------------------------
  ; Normalize PRF
  ;---------------------------------------------------------------
  prf_norm = prf_scaled / total(prf_scaled)
  prf_norm = prf_norm * scale_factor
  
  ;---------------------------------------------------------------
  ; Insert scaled PRF into output image
  ;---------------------------------------------------------------
  imout = im

  if keyword_set(verbose) then begin
    print, "Input image size: ", size(imout)
    print, "SIZE of Normalized PRF: ", size(prf_norm)
    print, "STDDEV of subregion: ", $
           stdev(imout[x0-new_xsize/2:x0+new_xsize/2, y0-new_ysize/2:y0+new_ysize/2])
    print, "MAX of Normalized PRF: ", MAX(prf_norm)
    print, "TOTAL of Normalized PRF: ", total(prf_norm)
    print, "=====END PLACE_PRF====="
  endif

  imout[x0-new_xsize/2:x0+new_xsize/2, $
        y0-new_ysize/2:y0+new_ysize/2] += prf_norm
end
