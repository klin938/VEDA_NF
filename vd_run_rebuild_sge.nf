#!/usr/bin/env nextflow

ch_progress = channel.watchPath("${workflow.workDir}/nf_probe_progress_state", 'modify')

process progressCheck {

        """
        ${workflow.projectDir}/vd_progress_check_sge.sh '${params.sgeQueue}' '${params.safe}' '${params.done}' '${workflow.workDir}'
        """
}

process checkSurvival {

        input:
        file "p" from ch_progress

        output:
        file 'nf_probe_survive' optional true into ch_survival

        """
        ${workflow.projectDir}/vd_check_survival_sge.sh '${params.sgeQueue}' '${params.survival}'
        """
}

process findMismatch {
	
	input:
	file "s" from ch_survival

	output:
	file 'nf_probe_mismatch' optional true into ch_mismatch
	
	"""	
	${workflow.projectDir}/vd_find_mismatch_sge.sh '${params.sgeQueue}'
	"""
}

process disable {

	input:
	file "m" from ch_mismatch

	output:
	file 'nf_probe_disabled' optional true into ch_disabled
	
	"""
	${workflow.projectDir}/vd_disable_q_ins_sge.sh ${m} mismatch
	"""
}

process rebuild {

	input:
	file "d" from ch_disabled
	
	"""
	${workflow.projectDir}/vd_rebuild_q_ins_rocks.sh ${d}
	"""
}
