# ; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
# ;	Unauthorized reproduction prohibited without touting Darkhan's
# ;	name. Please help me live forever by continuing the tradition
# ;	of honoring science nerds of the past by putting their name in
# ;	your code that uses theirs. 
# ;
# ;+
# ; NAME:
# ; FLUX_SNR5
# ;
# ; PURPOSE:
# ; This here Python script calculates the 5-sigma sensitivity limits for IRAC data by performing linear regression on signal-to-noise ratio versus flux measurements across multiple channels.
# ;
# ; CATEGORY:
# ; Astronomy, Sensitivity Analysis, IRAC Data Processing
# ;
# ; CALLING SEQUENCE:
# ; python flux_snr5.py -i input_file -o output_file [--plot]
# ;
# ; INPUTS:
# ; input_file: The input data file containing photometry results with columns for source name, channel, flux factors, photometry measurements, and uncertainties.
# ;
# ; OUTPUTS:
# ; output_file: The output file containing 5-sigma sensitivity limits for each source across all IRAC channels.
# ;
# ; KEYWORD PARAMETERS:
# ; --plot: Set this flag to generate diagnostic plots showing the linear fit and 5-sigma flux determination for each channel.
# ;
# ; PROCEDURE:
# ; The script reads photometry data, calculates signal-to-noise ratios, performs linear regression of SNR versus flux, and determines the flux value corresponding to SNR=5 for each source and channel.
# ;
# ; EXAMPLE:
# ; Calculate 5-sigma sensitivity limits and generate plots:
# ;
# ; python flux_snr5.py -i result.coldat -o snr5_result.coldat --plot
# ;
# ; MODIFICATION HISTORY:
# ; 	Written by:	Darkhan Nurzhakyp 2025 September 30
# ;	September,2025	Any additional mods get described here.  Remember to
# ;			change the stuff above if you add a new keyword or
# ;			something!
# ;-

import argparse
import numpy as np
import pandas as pd
from scipy.interpolate import interp1d
from scipy.optimize import root_scalar
import matplotlib.pyplot as plt
from scipy import stats


# Per-channel no_bgnd values (µJy)
# NO_BGND_PER_CH = [3.29734*8.47*1.125, 3.00630, 2.73935, 2.46965]
NO_BGND_PER_CH = [8.47*1.125]
WINDOW_SIZE = 9

# ;-----------------------------------------------------------------
# ;               Mini-Routines (main routine comes last)
# ;-----------------------------------------------------------------

def std(data, window_size):
    stds = []
    for i in range(0, len(data), window_size):
        window = data[i : i + window_size]
        stds.append(np.std(window))
    return np.array(stds)

# ;-----------------------------------------------------------------
# ;-----------------------------------------------------------------
# ;                             Main Routine
# ;-----------------------------------------------------------------
# ;-----------------------------------------------------------------

def process_all_magnetars(infile, outfile, plot=False):
    df = pd.read_csv(infile, comment='#', sep='\s+',
                     names=['name', 'ra', 'dec', 'ch', 'x', 'y', 'factor', 'phot', 'sigma'])
    result_lines = ['# name\tch1_sens5(µJy)\tch2_sens5(µJy)\tch3_sens5(µJy)\tch4_sens5(µJy)']

    for name in np.unique(df['name']):
        sub = df[df['name'] == name]
        row_result = [name]

        for ch in range(1, 5):
            ch_data = sub[sub['ch'] == ch]
            if len(ch_data) == 0:
                row_result.append(np.nan)
                continue

            factors = np.array(ch_data['factor'])
            phot_values = np.array(ch_data['phot'])

            if len(phot_values) % WINDOW_SIZE != 0:
                print(f"⚠️ Warning: samples not divisible by {WINDOW_SIZE} for {name}, channel {ch}")
                row_result.append(np.nan)
                continue

            base_factor = 1.0
            base_no_bgnd = NO_BGND_PER_CH[ch - 1]
            no_bgnd = (factors / base_factor) * base_no_bgnd
            delta = phot_values - no_bgnd
            stds = std(delta, WINDOW_SIZE)
            snrs = no_bgnd[::WINDOW_SIZE] / stds

            x_data = no_bgnd[::WINDOW_SIZE]
            y_data = snrs
            #start new code
            slope, intercept, r_value, p_value, std_err = stats.linregress(x_data, y_data)

            y_target = 5.0
            flux_at_snr5 = (y_target - intercept) / slope

            # Estimate residual standard deviation
            y_fit = slope * x_data + intercept
            residuals = y_data - y_fit
            sigma = np.std(residuals)  # estimated error per point

            # Dense x for plotting the fitted line
            x_dense = np.linspace(x_data.min(), max(x_data.max(), flux_at_snr5 * 1.1), 500)
            y_dense = slope * x_dense + intercept

            # Plot
            plt.figure(figsize=(7,5))
            plt.errorbar(x_data, y_data, yerr=sigma, fmt='o', label='Data (±σ)', capsize=4)
            plt.plot(x_dense, y_dense, '-', label=f'Fit: y = {slope:.4f}x + {intercept:.4f}')
            plt.axhline(y_target, color='red', linestyle='--', label=f'SNR={y_target}')
            plt.axvline(flux_at_snr5, color='green', linestyle='--',
                        label=f'Flux@SNR=5 = {flux_at_snr5:.2f}')
            plt.title("Linear Fit to SNR Data with Error Bars")
            plt.xlabel("Flux (µJy)")
            plt.ylabel("SNR")
            plt.legend()
            plt.grid(True)
            plt.show()

            print(f"Slope = {slope:.6f} ± {std_err:.6f}")
            print(f"Intercept = {intercept:.6f}")
            print(f"x value when y=5.0 → {flux_at_snr5:.2f} µJy")

            row_result.append(flux_at_snr5)

        result_lines.append('\t'.join(f'{v}' if isinstance(v, str) else f'{v:.6f}' for v in row_result))

    with open(outfile, 'w') as f:
        f.write('\n'.join(result_lines) + '\n')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', type=str, default="result.coldat", help="coldat file with circapphot data")
    parser.add_argument('-o', '--output', type=str, default="./../results/snr5_result.coldat", help="Output coldat result")
    parser.add_argument('--plot', action='store_true', help="Plot SNR vs Flux curve for each channel")
    args = parser.parse_args()
    
    process_all_magnetars(args.input, args.output, plot=args.plot)

if __name__ == "__main__":
    main()
