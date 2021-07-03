#!/bin/bash

queue="$(echo $1 | awk -F"@" '{print $1}')"
pattern="$(echo $1 | awk -F"@" '{print $2}')"

todo_list="$(qstat -f | grep "^$1" | awk '{print $1}')"
d_list="$(qstat -f -qs d)" # list of disabled nodes

if [[ -z "$todo_list" ]]
then
	printf "INFO: todo_list is empty, Cannot find any queue instances\n"
	exit 2
else
	printf "$todo_list\n"
fi

while read -r q_ins; do
	queue="$(echo $q_ins | awk -F"@" '{print $1}')"
	host="$(echo $q_ins | awk -F"@" '{print $2}')"
	
	# Just add anything as 2nd arg for verbose output
	if [[ ! -z $2 ]]; then
		printf "\n########################### $queue (at) $host ###########################\n"
	fi

	ver_check="$(ssh "$host" '/opt/dice_host_utils/check_ver_mismatch.sh' < /dev/null)"
	
	if [[ "$ver_check" == *"OK"* ]]
	then
		if grep -q "$q_ins" <<< "$d_list"
		then
			printf "\nEnabled: "
			qmod -e "$q_ins"
		else
			printf "\nSKIPPED: $q_ins already in the specified state: enabled.\n"
		fi
	else
		printf "\nSKIPPED: $q_ins versions mismatch!\n"
	fi
done <<< "$(echo "$todo_list")"

exit 0
