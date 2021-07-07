#!/bin/bash

if [[ -z "$1" ]]
then
	printf "Usage: $0 FILE_QUEUE_INS [slacker|mismatch]\n"
	exit 2
fi

target="${2:-slacker}"
d_list="$(qstat -f -qs d)" # list of disabled nodes

todo_list="$(cat $1)"

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
	then
		if [[ "$target" == "mismatch" ]]
		then
			#printf "$q_ins\n"
			disabled="${disabled}${q_ins}\n"
			qmod -d "$q_ins" > /dev/null
		else
			cpu_slots="$(qstat -f -q "$q_ins" | grep "$q_ins" | awk '{print $3}')"
			cpu_used="$(echo "$cpu_slots" | awk -F"/" '{print $2}')"
		
			if [[ "$cpu_used" -eq 0 ]]
			then
				#printf "$q_ins\n"
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
	printf "$disabled" > nf_probe_disabled
	cat nf_probe_disabled
fi

exit 0
