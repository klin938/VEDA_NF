#!/bin/bash

if [[ -z "$1" ]]
then
	printf "Usage: $0 INPUT_FILE(list of queue instances)\n"
	exit 2
fi

todo_list="$(cat $1)"

if [[ -z "$todo_list" ]]
then
        printf "INFO: todo_list is empty, Cannot find any queue instances from $1\n"
        exit 2
fi

d_list="$(qstat -f -qs d)" # list of disabled nodes

while read -r q_ins; do
	# we do NOT touch the nodes that have been disabled. This ensures
	# only the nodes disabled by this execution are included.
	if ! grep -q "$q_ins" <<< "$d_list"
	then
		cpu_slots="$(qstat -f -q "$q_ins" | grep "$q_ins" | awk '{print $3}')"
		cpu_used="$(echo "$cpu_slots" | awk -F"/" '{print $2}')"
		
		if [[ "$cpu_used" -eq 0 ]]
		then
			printf "$q_ins\n"
			qmod -d "$q_ins" > /dev/null
		fi
	fi
done <<< "$(echo "$todo_list")"

exit 0
