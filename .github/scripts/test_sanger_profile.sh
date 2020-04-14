#!/bin/bash
set -eo pipefail
export PATH=/opt/conda/bin:$PATH

# test --sanger profile
# there are only 2 available cpus in the github runner execution
sed -i s'/cpus = 4/cpus = 2/'g conf/coguk/sanger.config
echo run pipeline with sanger profile >> artifacts/test_artifact.log
NXF_VER=20.03.0-edge nextflow run ./main.nf \
       -profile sanger,singularity \
       --directory $PWD/.github/data/ \
       --illumina \
       --prefix test
cp .nextflow.log ./artifacts/sanger.profile.nextflow.log

# check that sanger profile activated 4 cpus on bwa mem:
find work -name .command.err \
    | xargs cat | grep '\[main\] CMD: bwa mem -t 2' \
    && echo "sanger profile: bwa started with 4 cpus" \
	|| exit 1

# check that sanger profile activated params.allowNoprimer = false:
find work -name .command.sh \
    | xargs cat | grep 'ivar trim -e' \
    && exit 1 \
	|| echo "sanger profile: did NOT ran ivar trim -e" 

# clean-up for following tests
mv results results_sanger_profile
rm -rf work && rm -rf .nextflow*
