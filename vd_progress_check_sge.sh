#!/bin/bash

# Usage: $0 [QUEUE] [SAFE_RATE] [DONE_RATE] [PROBE_DIR]
#
# SAFE_RATE: when the progress is below SAFE_RATE, we will disable "slacker" only.
#            when the progress is above SAFE_RATE, we will disable the rest of the ver mismatch nodes
#
# DONE_RATE: indicates completion. Normally it's 1 (100%)
#
# PROBE_DIR: where to generate signal files which are used by nextflow

exec > /tmp/vd_progress_check_sge.log
exec 2>&1

q="${1:-short.q}"
safe="${2:-0.50}"
done="${3:-1}"
nf_probe_dir="${4:-/tmp}"
nf_probe_file="$nf_probe_dir"/nf_probe_progress_state

count_all="$(qstat -f -q $q | grep $q | wc -l)"

while :
do
	current_time="$(date "+%Y.%m.%d-%H.%M.%S")"

	count_mismatch="$(vd_find_mismatch_sge.sh $q | wc -l)"
	count_completed="$(( count_all - count_mismatch ))"
	current="$(echo "scale=2; $count_completed/$count_all" | bc)"
	
	if (( $(echo "$current < $done" | bc -l) ))
	then
		if (( $(echo "$current > $safe" | bc -l) ))
		then
			state="SAFE"
		else
			state="BAD"
		fi
		
		printf "$state [ $current_time | All: $count_all | Completed: $count_completed | Progress: $current ]\n"
		echo "$state" >> "$nf_probe_file"
		sleep 5s
	else
		printf "DONE [ $current_time | All: $count_all | Completed: $count_completed | Progress: $current ]\n"
		exit 0
	fi
done


