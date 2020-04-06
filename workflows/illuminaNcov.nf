#!/usr/bin/env nextflow

// enable dsl2
nextflow.preview.dsl = 2

// import modules
include {articDownloadScheme } from '../modules/artic.nf' 
include {makeIvarBedfile} from '../modules/illumina.nf' 
include {cramToFastq} from '../modules/illumina.nf'
include {readTrimming} from '../modules/illumina.nf' 
include {readMapping} from '../modules/illumina.nf' 
include {trimPrimerSequences} from '../modules/illumina.nf' 
include {callVariants} from '../modules/illumina.nf'
include {makeConsensus} from '../modules/illumina.nf' 

include {makeQCCSV} from '../modules/qc.nf'
include {writeQCSummaryCSV} from '../modules/qc.nf'

include {collateSamples} from '../modules/upload.nf'

// import subworkflows
include {CLIMBrsync} from './upload.nf'


workflow sequenceAnalysis {
    take:
      ch_filePairs

    main:
      readTrimming(ch_filePairs)

      if (params.schemeRepoURL =~ /^http/) {
        articDownloadScheme()
        readMapping(articDownloadScheme.out.scheme.combine(readTrimming.out))
        trimPrimerSequences(articDownloadScheme.out.bed.combine(readMapping.out))
        callVariants(trimPrimerSequences.out.ptrim.combine(articDownloadScheme.out.reffasta))
      } else {
        localScheme = Channel.fromPath(params.schemeRepoURL)
        readMapping(localScheme.combine(readTrimming.out))
        localBed = Channel.fromPath("${params.schemeRepoURL}/**/${params.schemeVersion}/${params.scheme}.bed")
        trimPrimerSequences(localBed.combine(readMapping.out))
        localRef = Channel.fromPath("${params.schemeRepoURL}/**/${params.schemeVersion}/*.reference.fasta")
        callVariants(trimPrimerSequences.out.ptrim.combine(localRef))
      }

      makeConsensus(trimPrimerSequences.out.ptrim)

      if (params.schemeRepoURL =~ /^http/) {
        makeQCCSV(trimPrimerSequences.out.ptrim.join(makeConsensus.out, by: 0)
                                     .combine(articDownloadScheme.out.reffasta))
      } else {
        localRef = Channel.fromPath("${params.schemeRepoURL}/**/${params.schemeVersion}/*.reference.fasta")
        makeQCCSV(trimPrimerSequences.out.ptrim.join(makeConsensus.out, by: 0)
                                     .combine(localRef))
      }

      makeQCCSV.out.csv.splitCsv()
                       .unique()
                       .branch {
                           header: it[-1] == 'qc_pass'
                           fail: it[-1] == 'FALSE'
                           pass: it[-1] == 'TRUE'
    		       }
                       .set { qc }

     writeQCSummaryCSV(qc.header.concat(qc.pass).concat(qc.fail).toList())

     collateSamples(qc.pass.map{ it[0] }
                           .join(makeConsensus.out, by: 0)
                           .join(trimPrimerSequences.out.mapped))     

    emit:
      qc_pass = collateSamples.out
}

workflow ncovIllumina {
    take:
      ch_filePairs

    main:
      sequenceAnalysis(ch_filePairs)
 
      if ( params.upload ) {
        
        Channel.fromPath("${params.CLIMBkey}")
               .set{ ch_CLIMBkey }
      
        CLIMBrsync(sequenceAnalysis.out.qc_pass, ch_CLIMBkey )
      }

}

workflow ncovIlluminaCram {
    take:
      ch_cramDirectory
    main:
      cramToFastq(ch_cramDirectory)
      ncovIllumina(cramToFastq.out)
}

