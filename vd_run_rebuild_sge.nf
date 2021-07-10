#!/usr/bin/env nextflow

log.info """\
 V E D A - N F   S G E   R E B U I L D
 =========================================
 sgeQueue   : ${params.sgeQueue}
 safe       : % of completed nodes > ${params.safe}
 done       : % of completed nodes = ${params.done}
 survival   : % of disabled nodes <= ${params.survival}
 Log        : ${params.progressLog}
 """

Channel
	.watchPath( "${workflow.workDir}/nf_probe_progress_state", 'modify' )
	.set { ch_progress }

Channel
	.watchPath( "${workflow.workDir}/nf_probe_mismatch", 'modify' )
	.set { ch_mismatch }

Channel
	.watchPath( "${workflow.workDir}/nf_probe_disabled", 'modify' )
	.set { ch_disabled }


process progressCheck {

        """
        ${workflow.projectDir}/vd_progress_check_sge.sh '${params.sgeQueue}' '${params.safe}' '${params.done}' '${workflow.workDir}'
        """
}

process checkSurvival {

        input:
        file p from ch_progress

        output:
        file 'nf_probe_survive' optional true into ch_survival

        """
        ${workflow.projectDir}/vd_check_survival_sge.sh '${params.sgeQueue}' '${params.survival}'
        """
}

process findMismatch {
	
	input:
	file s from ch_survival

	"""	
	${workflow.projectDir}/vd_find_mismatch_sge.sh '${params.sgeQueue}' '${workflow.workDir}'
	"""
}

process disable {

	input:
	file m from ch_mismatch

	"""
	state=\$(cat ${workflow.workDir}/nf_probe_progress_state)
	if [[ \$state == *"BAD"* ]]; then
		${workflow.projectDir}/vd_disable_q_ins_sge.sh ${m} slacker '${workflow.workDir}'
		printf "[SLACKER DISABLED]:\n" > '${workflow.workDir}/disable_method'
	elif [[ \$state == *"SAFE"* ]]; then
		${workflow.projectDir}/vd_disable_q_ins_sge.sh ${m} mismatch '${workflow.workDir}'
		printf "[MISMATCH DISABLED]:\n" > '${workflow.workDir}/disable_method'
	else
		:
	fi
	"""
}

process rebuild {

	input:
	file d from ch_disabled
	
	"""
	cat ${workflow.workDir}/disable_method >> '${params.progressLog}'
	cat ${d} >> '${params.progressLog}'
	${workflow.projectDir}/vd_rebuild_q_ins_rocks.sh ${d}
	"""
}
