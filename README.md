## Spitzer Photometry Program

Estimate 5σ flux sensitivity for Spitzer/IRAC observations of magnetars. The pipeline places synthetic PRFs, performs circular aperture photometry (IDL), aggregates intermediate measurements into `.coldat`, and fits SNR–flux to derive the flux at SNR=5 (Python).

### Repository structure
- `configs/` — example configuration tables (`.coldat`) for IDL procedures
- `mag_info/` — object lists and helper tables
- `prf/` — PRF libraries for IRAC channels
- `simtar_partial/` — directory layout expected by the pipeline (`mosaici1..4/`)
- `src/` — IDL and Python sources, plus a convenience runner script
- `results/` — example outputs and intermediates
- `plots/` — example figures produced by the Python fit

### Requirements
- IDL (tested with IDL 8+), with supporting routines available at run time:
  - `readcoldat`, `irac_limit`, `adxy`, `readfits`, `get_annulus` (by request), `circapphot` (by request) must be on `!PATH`
- Python 3.7+
  - Install Python deps via `src/requirements.txt` (NumPy, SciPy, Pandas, Matplotlib)

### Quick start: Python-only (compute SNR=5 from an existing coldat)
If you already have an intermediate photometry table (see format below), run:

```bash
cd src
./run_py.sh ../results/intermed/result_1e2259.coldat ../results/result_py.coldat
```

This will:
- create a virtualenv in `src/.env` (if missing),
- install requirements, and
- run `flux_snr5.py -i <input> -o <output> --plot`.

The output is a `.coldat` table with one row per source containing estimated ch1–ch4 fluxes at SNR=5 (NaN where unavailable). With `--plot`, diagnostic SNR–flux fits will display.

### Full pipeline (IDL → Python)
1) Generate intermediate photometry with IDL

In IDL:
```idl
.r src/main.pro
run_irac_limit, 'configs/sample_config.coldat'
```

This reads the config, iterates over sources and channels, places PRFs, performs circular aperture photometry, and writes an intermediate `.coldat` specified by the config. The file has one line per placement with columns (see below).

2) Optional: Extract local exposure time (IDL)

In IDL:
```idl
.r src/texp.pro
extract_texp, 'configs/texp.coldat'
```

This scans mosaic FITS files in `simtar_partial/<target>/mosaici<ch>/Coadd/` and writes per-channel exposure time around the target to the output coldat listed in the config.

3) Fit SNR–flux to get 5σ flux (Python)

```bash
cd src
./run_py.sh ../results/intermed/intermed_result.coldat ../results/result.coldat
```

Or directly:
```bash
cd src
python3 -m venv .env && source .env/bin/activate
pip install -r requirements.txt
python3 flux_snr5.py -i ../results/intermed/intermed_result.coldat -o ../results/result.coldat --plot
deactivate
```
### Example output
![Example](docs/igure_1.png)

### File formats
- Intermediate photometry (`.coldat`) — produced by `run_irac_limit` and consumed by `flux_snr5.py`. Space-separated with header like:
  - `# name  ra  dec  ch  x  y  factor  phot  sigma`
  - Multiple rows per source and channel across PRF scaling factors.

- SNR=5 result (`.coldat`) — produced by Python, one row per source:
  - `# name  ch1_sens5(µJy)  ch2_sens5(µJy)  ch3_sens5(µJy)  ch4_sens5(µJy)`

- Exposure time (`.coldat`) — produced by `extract_texp`:
  - `# name  ch1_texp(s)  ch2_texp(s)  ch3_texp(s)  ch4_texp(s)`

### Configuration (IDL)
`configs/darkhan_config.coldat` drives `run_irac_limit`. Fields include (by row index as used in code):
- `[0] input_path` — magnetar list (`.coldat`) with folder, RA, Dec
- `[1] output_path` — intermediate photometry output path
- `[2] data_path` — base path containing `simtar_partial`
- `[3] factors` — array literal like `[1.,5.,10., 20., 30.]` for total PRF 
- `[4] rap` — aperture radius (pix)
- `[5] rbackin`, `[6] rbackout` — background annulus (pix)
- `[7] spacing` — PRF placement spacing (pix)
- `[8] prf_path` — PRF library root (e.g., `prf/070131_prfs_for_apex_v080827_ch1`)
- `[9] result_path` — final SNR=5 output path (used by spawn of Python step)
- `[10] channels` — array literal like `[1,2,3,4]` for IRAC channels
- `[11] test_path` — extra diagnostics output to store internal test results

`configs/texp.coldat` drives `extract_texp` (see `src/texp.pro`).

### Notes on the Python fit (`src/flux_snr5.py`)
- Reads the intermediate table, groups by source and channel, computes SNR at each PRF factor and performs a linear regression `SNR = a·Flux + b` to solve for `SNR=5`.
- Use `--plot` to display diagnostics and an estimated per-point scatter.
- Defaults: sliding window size is 9; channel constants can be tuned in the script.

### Data layout expected
```
simtar_partial/
  <source>/
    mosaici1/Coadd/*.fits
    mosaici2/Coadd/*.fits
    mosaici3/Coadd/*.fits
    mosaici4/Coadd/*.fits
prf/
  070131_prfs_for_apex_v080827_ch1/...
  070131_prfs_for_apex_v080827_ch2/...
  070131_prfs_for_apex_v080827_ch3/...
  070131_prfs_for_apex_v080827_ch4/...
```

### Troubleshooting
- Ensure IDL helper routines (`readcoldat`, `irac_limit`, etc.) are on the IDL path.
- If Python plots do not display in headless environments, remove `--plot` or use a non-interactive Matplotlib backend.
- Verify paths in `configs/*.coldat` are absolute or correct relative paths.



