#!/bin/bash

# slacker: bad nodes without any active SGE running jobs
# resister: remaining bad nodes when rebuild progress meets SAFE level

if [[ -z "$1" ]]
then
	printf "Usage: $0 FILE_QUEUE_INS [slacker|resister] [NF_CHANNEL_FILE_DIR]\n"
	exit 2
else
	todo_list="$(cat $1)"
fi

target="${2:-slacker}"
nf_probe_dir="${3:-/tmp}"
nf_probe_file="$nf_probe_dir"/nf_probe_disabled

d_list="$(qstat -f -qs d)" # list of disabled nodes

if [[ -z "$todo_list" ]]
then
        printf "INFO: todo_list is empty, Cannot find any queue instances from $1\n"
        exit 2
fi

disabled=""
while read -r q_ins; do
	# we do NOT touch the nodes that have been disabled. This ensures
	# only the nodes disabled by this execution are included.
	if ! grep -q "$q_ins" <<< "$d_list"
	then	# disable all remaining bad nodes
		if [[ "$target" == "resister" ]]
		then
			disabled="${disabled}${q_ins}\n"
			qmod -d "$q_ins" > /dev/null
		else
			cpu_slots="$(qstat -f -q "$q_ins" | grep "$q_ins" | awk '{print $3}')"
			cpu_used="$(echo "$cpu_slots" | awk -F"/" '{print $2}')"
		
			if [[ "$cpu_used" -eq 0 ]]
			then
				disabled="${disabled}${q_ins}\n"
				qmod -d "$q_ins" > /dev/null
			fi
		fi
	else
		printf "SKIPPED: $q_ins has been disabled outside this execution.\n"
	fi
done <<< "$(echo "$todo_list")"

if [[ ! -z "$disabled" ]]
then
	printf "$disabled" > "$nf_probe_file"
	cat "$nf_probe_file"
fi

exit 0
