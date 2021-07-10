#!/bin/bash

# Usage: $0 [QUEUE] [SAFE_RATE] [DONE_RATE] [NF_CHANNEL_FILE_DIR]
#
# SAFE_RATE: when the progress is BELOW SAFE_RATE, we will disable "slacker" only.
#            when the progress is ABOVE SAFE_RATE, we will disable "resister" nodes
#
# DONE_RATE: indicates completion. Normally it's 1 (100%)
#
# NF_CHANNEL_FILE_DIR: where to generate signal file which are used by nextflow channel


LOG="/tmp/vd_progress_check_sge.log"

q="${1:-short.q}"
safe="${2:-0.50}"
done="${3:-1}"
nf_probe_dir="${4:-/tmp}"
nf_probe_file="$nf_probe_dir"/nf_probe_progress_state

count_all="$(qstat -f -q $q | grep $q | wc -l)"

printf "#################### Started: $(date "+%Y.%m.%d-%H.%M.%S") ####################\n" >>  "$LOG"
printf "## sgeQueue   : $q\n## safe       : %% of completed nodes > $safe\n## done       : %% of completed nodes = $done\n" >> "$LOG"
printf "######################################################################\n" >> "$LOG"

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
			sleep_time="120m"
		else
			state="BAD"
			sleep_time="1m"
		fi
		
		printf "$state [ $current_time | All: $count_all | Completed: $count_completed | Progress: $current ]\n" >> "$LOG"
		echo "$state" > "$nf_probe_file"
		sleep "$sleep_time"
	else
		printf "DONE [ $current_time | All: $count_all | Completed: $count_completed | Progress: $current ]\n\n\n" >> "$LOG"
		exit 0
	fi
done


