#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
generator=${1:-"$repo_root/shovill_SLURM_array.sh"}
input_fixture="$repo_root/tests/sample_list_input_fixtures.txt"
expected_fixture="$repo_root/tests/expected_slurm_array_fixtures.txt"

if [[ "$generator" != /* ]]; then
    generator="$repo_root/$generator"
fi

for required_file in "$generator" "$input_fixture" "$expected_fixture"; do
    if [[ ! -f "$required_file" ]]; then
        echo "FAIL: required file not found: $required_file" >&2
        exit 1
    fi
done

test_dir=$(mktemp -d "${TMPDIR:-/tmp}/shovill_slurm_array_XXXXXX")
trap 'rm -rf "$test_dir"' EXIT

sample_list="$test_dir/sample_list_input_fixtures.txt"
actual="$test_dir/sample_list_input_fixtures_SLURM-ARRAY-READY.txt"
intermediate="$test_dir/sample_list_input_fixtures_R1s.txt"

cp "$input_fixture" "$sample_list"

(
    cd "$test_dir"
    bash "$generator" "$sample_list"
)

if [[ ! -f "$actual" ]]; then
    echo "FAIL: generator did not create $actual" >&2
    exit 1
fi

if ! diff -u "$expected_fixture" "$actual"; then
    echo "FAIL: generated SLURM array records differ from the fixture" >&2
    exit 1
fi

if [[ -e "$intermediate" ]]; then
    echo "FAIL: temporary R1 list was not removed" >&2
    exit 1
fi

echo "PASS: SLURM array generation matches all fixtures"
