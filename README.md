# Shovil

Wrapper for running Shovill assemblies in parallel. Use locally or `sbatch` the script directly with `mode=local`.

## Setup

```bash
git clone <repo-url>
cd Shovil
conda env create -f env_shovill.yml
```
or just set up the env yourself.

## Usage

### Local

```bash
bash shovill_runner_script.sh -i /path/to/reads -o /path/to/output -c scripts/config.env
```

### Slurm

Submit the script directly:

```bash
sbatch scripts/shovill_runner_script.sh -i /path/to/reads -o /path/to/output -c scripts/config.env
```

Slurm directives are set at the top of the script; edit them there or override with `sbatch` flags.

## Script functions

- `help()` — show usage note
- `validate_input()` — check input dir, output dir and config file exist
- `load_config_values()` — read variables from `config.env`
- `activate_conda_env()` — activate the configured conda environment
- `create_output_structure()` — create `processing_files/`, `compiled_files/` and `slurm_output/`
- `create_unique_ID_list()` — list sample IDs from R1 filenames
- `create_ID_PATH_list()` — create `sample_list.tsv` with sample ID, R1 path, R2 path
- `create_shovill_commands_file()` — write one `shovill` command per sample to `shovill_commands.txt`
- `create_shovill_command_parallel()` — build the GNU `parallel` command
- `aggregate_fasta_files_with_symlink()` — symlink all `*.fa` assemblies into `compiled_files/`
- `move_slurm_stderr_stdout()` — move Slurm `.out`/`.err` files into `slurm_output/`
- `run_cmd_via_slurm()` — **deprecated**, previously submitted commands via `sbatch`