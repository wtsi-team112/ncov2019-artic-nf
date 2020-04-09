#!/bin/bash
set -eo pipefail
export PATH=/opt/conda/bin:$PATH

# write log as github Action artifact
mkdir artifacts
echo run tests >> artifacts/test_artifact.log

# run current pull request code
singularity --version
NXF_VER=20.03.0-edge nextflow run ./main.nf \
       -profile singularity \
       --directory $PWD/.github/data/ \
       --illumina \
       --prefix test
cp .nextflow.log artifacts/

# run upstream connor-lab fork
git clone https://github.com/connor-lab/ncov2019-artic-nf.git upstream_fork
cd upstream_fork
ln -s ../*.sif ./
NXF_VER=20.03.0-edge nextflow run ./main.nf \
       -profile singularity \
       --directory $PWD/../.github/data/ \
       --illumina \
       --prefix test
cp .nextflow.log ../artifacts/upstream.nextflow.log
cd ..

# exclude files from comparison
# and list differences
find results ./upstream_fork/results \
     -name "test.qc.csv" \
     -o -name "*.fq.gz" \
     -o -name "scheme" | xargs rm -rf
git diff --stat --no-index results ./upstream_fork/results > diffs.txt
if [ -s diffs.txt ]
then
  echo differences found between pull request and upstream fork       
  cp diffs.txt artifacts/  
  exit 1
else
  echo no differences found between pull request and upstream fork       
fi

# test --sanger profile
mv results results_singularity_profile
rm -rf work && rm -rf .nextflow*
# there are only 2 available cpus in the github runner execution
sed -i s'/cpus = 4/cpus = 2/'g conf/coguk/sanger.config
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

# test conda profile
# install Conda environments of the pipeline
#source .github/scripts/install_conda_envs.sh
# Run the tests
#echo run tests >> artifacts/test_artifact.log
#NXF_VER=20.03.0-edge nextflow run main.nf \
#       -profile conda \
#       --directory test_data/fastq \
#       --illumina \
#       --prefix test
