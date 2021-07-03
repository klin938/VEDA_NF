#!/bin/bash

queue="${1:-short.q}"

todo_list="$(qstat -f -q "$queue" | grep "$queue" | awk '{print $1}')"

if [[ -z "$todo_list" ]]
then
        printf "INFO: todo_list is empty, Cannot find any queue instances\n"
        exit 2
fi

au_list="$(qstat -f -qs au)" # list of nodes in au states
icu_grp="$(qconf -shgrp @icu)"

while read -r q_ins; do

        host="$(echo $q_ins | awk -F"@" '{print $2}')"
	# We ignore nodes in ICU or in au states
	if grep -q "$host" <<< "$icu_grp" || grep -q "$q_ins" <<< "$au_list"
	then
		:
	else
        	ver_check="$(ssh "$host" '/opt/dice_host_utils/check_ver_mismatch.sh' < /dev/null)"

        	if [[ "$ver_check" == *"BAD"* ]]
        	then
			printf "$q_ins\n"
		fi
        fi
done <<< "$(echo "$todo_list")"

exit 0

