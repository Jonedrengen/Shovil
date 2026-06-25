# Shovil

A simple SLURM wrapper for running Shovill assemblies.

## Usage
1. Configure `scripts/config.env` for your environment.
2. Put paired-end FASTQ files in an input folder.
3. Run `scripts/shovill_submitter.sh`.

## Included scripts
- `scripts/shovill_submitter.sh` — submit the workflow to SLURM
- `scripts/shovill_runner.sh` — run Shovill for one sample
- `scripts/shovill_aggregator.sh` — gather final outputs
- `scripts/shovill_SLURM_array.sh` — SLURM array support

## Notes
- Requires SLURM and Shovill available in the configured conda environment.
- Outputs are written under `processing_files/` and `compiled_files/`.

## Future
- Local version, using GNU parallel for parallizing and likely a docker container