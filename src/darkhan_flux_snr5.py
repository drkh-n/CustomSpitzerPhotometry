import argparse
import numpy as np
import pandas as pd
from scipy.interpolate import interp1d
from scipy.optimize import root_scalar
import matplotlib.pyplot as plt

# Per-channel no_bgnd values (µJy)
NO_BGND_PER_CH = [3.29734, 3.00630, 2.73935, 2.46965]
WINDOW_SIZE = 9

def std(data, window_size):
    stds = []
    for i in range(0, len(data), window_size):
        window = data[i : i + window_size]
        stds.append(np.std(window))
    return np.array(stds)

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

            base_factor = 1000.0
            base_no_bgnd = NO_BGND_PER_CH[ch - 1]
            no_bgnd = (factors / base_factor) * base_no_bgnd
            delta = phot_values - no_bgnd
            stds = std(delta, WINDOW_SIZE)
            snrs = no_bgnd[::WINDOW_SIZE] / stds

            x_data = no_bgnd[::WINDOW_SIZE]
            y_data = snrs

            try:
                interp_func = interp1d(x_data, y_data, kind='cubic', fill_value='extrapolate')

                def find_root(x):
                    return interp_func(x) - 5.0

                if np.any((y_data - 5.0) < 0) and np.any((y_data - 5.0) > 0):
                    # Safe interpolation
                    result = root_scalar(find_root, bracket=[x_data.min(), x_data.max()])
                    flux_at_snr5 = result.root
                    print(f"{name} ch{ch}: Flux at SNR=5 = {flux_at_snr5:.4f}")
                else:
                    # Extrapolation
                    result = root_scalar(find_root, bracket=[x_data.min(), x_data.max() * 2], method='brentq')
                    flux_at_snr5 = result.root
                    print(f"{name} ch{ch}: ⚠️ Extrapolated flux at SNR=5 = {flux_at_snr5:.4f}")

                if plot:
                    x_dense = np.linspace(x_data.min(), max(x_data.max(), flux_at_snr5 * 1.1), 500)
                    plt.figure()
                    plt.plot(x_data, y_data, 'o', label='SNR Data')
                    plt.plot(x_dense, interp_func(x_dense), '-', label='Interpolation')
                    plt.axhline(5, color='red', linestyle='--', label='SNR=5')
                    plt.axvline(flux_at_snr5, color='green', linestyle='--', label=f'Flux@SNR=5 = {flux_at_snr5:.2f}')
                    plt.title(f'{name} Channel {ch}')
                    plt.xlabel('Flux (µJy)')
                    plt.ylabel('SNR')
                    plt.legend()
                    plt.grid(True)
                    plt.show()

            except Exception as e:
                flux_at_snr5 = np.nan
                print(f"{name} ch{ch}: ❌ Failed interpolation - {e}")

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
