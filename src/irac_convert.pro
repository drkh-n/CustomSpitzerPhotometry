;---------------------------------------------------
; Convert IRAC mosaic data (MJy/sr) -> µJy/pixel
; Adds channel input (1–4).
; Includes aperture correction placeholders.
;---------------------------------------------------

pro irac_mosaic_mjysr_to_ujy, imgval, channel

    ;-------------------------------------------
    ; 1. Define constants
    ;-------------------------------------------
    arcsec_to_rad = !dpi / (180.d0 * 3600.d0)   ; radians per arcsec
    pixscale = 0.6d0                            ; arcsec/pixel (mosaic)
    mjy_to_jy = 1.0d6                           ; 1 MJy = 1e6 Jy
    jy_to_ujy = 1.0d6                           ; 1 Jy = 1e6 µJy

    ;-------------------------------------------
    ; 2. Pixel solid angle in steradians
    ;-------------------------------------------
    pixar_sr = (pixscale * arcsec_to_rad)^2

    ;-------------------------------------------
    ; 3. Channel-specific parameters
    ;-------------------------------------------
    ; Aperture correction values (example: 3-pixel radius, in BCD scale)
    ; Replace with correct table from IRAC handbook if needed
    aper_corr = [1.125d0, 1.120d0, 1.135d0, 1.221d0]
    ;  apcor = [1.125, 1.120, 1.135, 1.221]

    if (channel lt 1 or channel gt 4) then begin
        message, 'Channel must be between 1 and 4'
    endif

    this_corr = aper_corr[channel-1]

    ;-------------------------------------------
    ; 4. Convert from MJy/sr -> Jy/pixel
    ;-------------------------------------------
    jy_per_pixel = imgval * mjy_to_jy * pixar_sr

    ;-------------------------------------------
    ; 5. Convert Jy -> µJy
    ;-------------------------------------------
    ujy_per_pixel = jy_per_pixel * jy_to_ujy

    ;-------------------------------------------
    ; 6. Apply aperture correction (optional)
    ;-------------------------------------------
    ujy_corr = ujy_per_pixel * this_corr

    ;-------------------------------------------
    ; Print all steps
    ;-------------------------------------------
    print, 'Input value (MJy/sr): ', imgval
    print, 'Channel: ', channel
    print, 'Pixel scale (arcsec): ', pixscale
    print, 'Arcsec to rad:        ', arcsec_to_rad
    print, 'Pixel solid angle (sr): ', pixar_sr
    print, 'Value in Jy/pixel:    ', jy_per_pixel
    print, 'Value in µJy/pixel:   ', ujy_per_pixel
    print, 'Aperture correction:  ', this_corr
    print, 'Corrected µJy/pixel:  ', ujy_corr

end
