#!/usr/bin/env nextflow

ch_progress = channel.watchPath("${workflow.workDir}/vd_prog.*")

process progressCheck {

        """
        ${workflow.projectDir}/vd_progress_check_sge.sh '${params.sgeQueue}' '${params.completedRate}' '${workflow.workDir}'
        """
}

process showProgress {

        input:
        file p from ch_progress

        output:
        stdout result

        """
        cat $p
        """
}

result.view { it.trim() }

