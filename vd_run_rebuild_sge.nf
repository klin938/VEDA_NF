#!/usr/bin/env nextflow

log.info """\
 V E D A - N F   S G E   R E B U I L D
 =========================================
 sgeQueue   : ${params.sgeQueue}
 safe       : % of completed nodes > ${params.safe}
 done       : % of completed nodes = ${params.done}
 survival   : % of disabled nodes <= ${params.survival}
 """

Channel
	.watchPath( "${workflow.workDir}/nf_probe_progress_state", 'modify' )
	.into{ ch_progress; ch_state }

process progressCheck {

        """
        ${workflow.projectDir}/vd_progress_check_sge.sh '${params.sgeQueue}' '${params.safe}' '${params.done}' '${workflow.workDir}'
        """
}

process stateController {

        input:
        file 'state.txt' from ch_state

        output:
        file 'state_safe.txt' optional true into ch_safe_state
        file 'state_bad.txt' optional true into ch_bad_state

        """
        state=\$(cat state.txt)
        if [[ \$state == *"BAD"* ]]; then
                touch state_bad.txt
        elif [[ \$state == *"SAFE"* ]]; then
                touch state_safe.txt
        else
                :
        fi
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

	output:
	file 'nf_probe_mismatch' optional true into ch01_mismatch
	file 'nf_probe_mismatch' optional true into ch02_mismatch
	
	"""	
	${workflow.projectDir}/vd_find_mismatch_sge.sh '${params.sgeQueue}'
	"""
}

process disableSlacker {

	input:
	file m from ch01_mismatch
	file b from ch_bad_state

	"""
	${workflow.projectDir}/vd_disable_q_ins_sge.sh ${m} slacker '${workflow.workDir}'
	"""	
}

process disableMismatch {
	
	input:
	file m from ch02_mismatch
	file s from ch_safe_state

	"""
	${workflow.projectDir}/vd_disable_q_ins_sge.sh ${m} mismatch '${workflow.workDir}'
	"""
}

Channel
   .watchPath( "${workflow.workDir}/nf_probe_disabled", 'modify' )
   .set { ch_disabled }

process rebuild {

	input:
	file d from ch_disabled
	
	"""
	${workflow.projectDir}/vd_rebuild_q_ins_rocks.sh ${d}
	"""
}
