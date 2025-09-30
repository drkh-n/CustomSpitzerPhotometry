; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
;	Unauthorized reproduction prohibited without touting Darkhan's
;	name. Please help me live forever by continuing the tradition
;	of honoring science nerds of the past by putting their name in
;	your code that uses theirs. 
;
;+
; NAME:
; PLACE_PRF
;
; PURPOSE:
; This here procedure places a Point Response Function (PRF) into an image at a specified location with sub-pixel shifting and channel-specific scaling. The PRF is trimmed, shifted, scaled, normalized, and then added to the output image.
;
; CATEGORY:
; Image Processing, Astronomy
;
; CALLING SEQUENCE:
; PLACE_PRF, Im, Channel, X0, Y0, Xoff_Fracpix, Yoff_Fracpix, Prf, norm_factor, Imout
;
; INPUTS:
; Im: The input image array into which the PRF will be placed.
;
; Channel: The instrument channel (1, 2, 3, or 4) used to determine scaling factors.
;
; X0: The x-coordinate (column) in the image where the PRF center is to be placed.
;
; Y0: The y-coordinate (row) in the image where the PRF center is to be placed.
;
; Xoff_Fracpix: The sub-pixel offset in the x-direction (in fraction of a pixel) to shift the PRF.
;
; Yoff_Fracpix: The sub-pixel offset in the y-direction (in fraction of a pixel) to shift the PRF.
;
; Prf: The input Point Response Function (PRF) array to be placed into the image.
;
; norm_factor: The factor by which the PRF is normalized before being added to the image.
;
; OUTPUTS:
; Imout: The output image with the PRF added at the specified location.
;
; KEYWORD PARAMETERS:
; VERBOSE: Set this keyword to print diagnostic information during execution. The default is to not print verbose output.
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

function get_channel_scaling_factors, channel
compile_opt IDL2
  CASE FIX(channel) OF
     1: p_prf = 1.221
     2: p_prf = 1.213
     3: p_prf = 1.222
     4: p_prf = 1.220
     ELSE: RETURN, {status: 0, message: 'Invalid channel'}
  ENDCASE
  
  ; Convert to relative scale
  p_prf    = p_prf / 100.0
  p_mosaic = 0.6
  s        = p_prf / p_mosaic
  
  return, {status: 1, scale: s}
end

function trim_prf, prf, verbose=verbose
compile_opt IDL2
  prf_dim   = size(prf)
  prf_xsize = prf_dim[1]
  prf_ysize = prf_dim[2]

  if keyword_set(verbose) then begin
    mx = MAX(prf, I)
    cx_prf = I MOD prf_xsize
    cy_prf = I / prf_ysize
    print, "Original PRF max value: ", mx
    print, "Original PRF max coords: ", STRTRIM(cx_prf,1), ",", STRTRIM(cy_prf,1)
  endif

  ; Trim 50-pixel borders of zeros
  prf_trimmed = prf[50:prf_xsize-51, 50:prf_ysize-51]

  if keyword_set(verbose) then begin
    mx = MAX(prf_trimmed, I)
    dim = size(prf_trimmed)
    cx_prf_trim = I MOD dim[1]
    cy_prf_trim = I / dim[2]
    print, "Trimmed PRF max value: ", mx
    print, "Trimmed PRF max coords: ", cx_prf_trim, ",", cy_prf_trim
  endif

  return, prf_trimmed
end

function compute_new_dimensions, channel, dim, scale
compile_opt IDL2
  IF (channel EQ 1) OR (channel EQ 3) THEN BEGIN
    new_xsize = ceil(dim[1] * scale)  ; even → ceil → odd
    new_ysize = ceil(dim[2] * scale)
  ENDIF ELSE IF (channel EQ 2) OR (channel EQ 4) THEN BEGIN
    new_xsize = floor(dim[1] * scale) ; odd → floor → odd
    new_ysize = floor(dim[2] * scale)
  ENDIF ELSE RETURN, {status: 0, message: 'Invalid channel'}

  return, {status: 1, xsize: new_xsize, ysize: new_ysize}
end

function shift_prf, prf_trimmed, xoff_fracpix, yoff_fracpix, scale
compile_opt IDL2
  dim = size(prf_trimmed)
  prf_shifted = prf_trimmed * 0.0
  max = dim[1] - 1

  shift_x = fix(xoff_fracpix / scale)
  shift_y = fix(yoff_fracpix / scale)

  prf_shifted[0:max-shift_x, 0:max-shift_y] = $
    prf_trimmed[shift_x:max, shift_y:max]

  return, prf_shifted
end

function scale_and_normalize_prf, prf_shifted, new_xsize, new_ysize, norm_factor, verbose=verbose
compile_opt IDL2
  prf_scaled = CONGRID(prf_shifted, new_xsize, new_ysize, /interp)
  
  if keyword_set(verbose) then begin
     print, 'PRF_shifted total= ', total(prf_shifted)
     print, 'PRF after CONGRID total= ', total(prf_scaled)
     sc = size(prf_scaled)
     print, "Max after CONGRID: ", MAX(prf_scaled, I)
     print, "Scaled PRF max coords: ", I MOD sc[1], ",", I / sc[2]
  endif

  ; Normalize PRF
  prf_norm = prf_scaled / total(prf_scaled)
  prf_norm = prf_norm * norm_factor

  return, prf_norm
end

;-----------------------------------------------------------------
;-----------------------------------------------------------------
;                             Main Routine
;-----------------------------------------------------------------
;-----------------------------------------------------------------

pro place_prf, im, channel, x0, y0, xoff_fracpix, yoff_fracpix, prf, norm_factor, imout, VERBOSE=verbose
compile_opt IDL2

  if keyword_set(verbose) then print, "=====PLACE_PRF====="

  ; Get channel-specific scaling factors
  scale_result = get_channel_scaling_factors(channel)
  if ~scale_result.status then return
  s = scale_result.scale

  ; Trim PRF
  prf_trimmed = trim_prf(prf, verbose=verbose)
  dim = size(prf_trimmed)

  ; Compute new dimensions
  dim_result = compute_new_dimensions(channel, dim, s)
  if ~dim_result.status then return
  new_xsize = dim_result.xsize
  new_ysize = dim_result.ysize

  ; Apply sub-pixel shift
  prf_shifted = shift_prf(prf_trimmed, xoff_fracpix, yoff_fracpix, s)

  ; Scale and normalize PRF
  prf_norm = scale_and_normalize_prf(prf_shifted, new_xsize, new_ysize, norm_factor, verbose=verbose)

  ; Insert scaled PRF into output image
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
