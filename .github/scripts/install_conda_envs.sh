#!/bin/bash
set -eo pipefail

conda env create -f environment-illumina.yml
conda env create -f environment-medaka.yml
conda env create -f environment.yml

