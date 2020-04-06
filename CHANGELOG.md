# Change Log
All notable changes to this project will be documented in this file.
"Upstream" refers to https://github.com/connor-lab/ncov2019-artic-nf, from
which this repo was forked and continues to be synced with.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this
project adheres to [Semantic Versioning](http://semver.org/).


## [2.0.0] - 2020-04-03
### Added
- Merge API-changing commits from upstream
  f0ba0a1493c9571f4eda161ae8d6afe02d0da570. Other additions, changes and
  fixes for this version are all from upstream.
- New bwa option to use it instead of minimap2 for minION.
- New bin/qc.py
- Main workflow now checks required parameters and exits with an error if
  not supplied correctly.
- QC filter samples to upload and make a QC summary CSV.
- New options for Illumina ivarMinFreqThreshold and ivarMinVariantQuality.
- New callVariants process in Illumina workflow that uses `samtools mpileup`
  and `ivar variants` for new tsv file output.

### Changed
- Use fieldbioinformatics conda environment instead of artic-ncov2019*.
- Default schemeVersion to 'V2' instead of 'V1'.
- Remove barcode and minimap options. Barcodes are automatically detected.
- articGather process renamed articGuppyPlex and now publishes (only) all
  fastq files. Removed articDemultiplex and nanopolishIndex processes, now
  handled by artic guppyplex.
- articMinIONNanopolish renamed articMinION, removed articMinIONMedaka
  process.
- workflows/articNcovNanopolish.nf deleted, and workflows/articNcovMedake.nf
  renamed workflows/articNcovNanopore.nf. Workflows unified and named
  articNcovNanopore.
- Upload untrimmed mapped bams, not the primertrimmed versions. Name bams
  after sampleName.
- Moved illumina-specific config variables from conf/base.config to
  conf/illumina.config, likewise for nanopore-specific variables.
- Usge of modules/upload.nf processes refactored in to new
  workflows/upload.nf
- readTrimming process uses gunzip instead of zcat.
- Illumina ivarFreqThreshold reduced to 0.75 from 0.9.
- Illumina ivarMinDepth reduced to 10 from 50.
- articDownloadScheme process now emits reffasta and scheme instead of just
  scheme. Workflows using this adjusted as necessary.
- articMinION process now emits primertrimmed and just mapped bams
  seperately, instead of just sorted bams.
- ivar 1.1_beta now used instead of 1.0.1.
- Use 6 column bed file in the scheme repository directly with ivar without
  any conversion.

### Fixed
- No more undefined config variables.
- ivar cmd line was missing `-m` option, so min length was not being used.


## [1.1.0] - 2020-27-03
### Added
- Cram to fastq conversion process, used with new `--cram` flag.
- LSF support with Sanger-specific conf/lsf.config and new `lsf` profile.

### Changed
- conf/base.config altered to default schemeVersion to 'V2' (was 'V1') and
  allowNoprimer to false (was true).
- schemeRepoURL can now be a local directory path to use your own clone of
  https://github.com/artic-network/artic-ncov2019.git


## [1.0.0] - 2020-24-03
### Added
- Start of fork, based on upstream b07c4351d3d6f9f73d867f82411148328811179f.
