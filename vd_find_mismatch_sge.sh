#!/bin/bash

queue="${1:-short.q}"
nf_probe_dir="${2:-/tmp}"
nf_probe_file="$nf_probe_dir"/nf_probe_mismatch

todo_list="$(qstat -f -q "$queue" | grep "$queue" | awk '{print $1}')"

if [[ -z "$todo_list" ]]
then
        printf "INFO: todo_list is empty, Cannot find any queue instances\n"
        exit 2
fi

au_list="$(qstat -f -qs au)" # list of nodes in au states
icu_grp="$(qconf -shgrp @icu)"

found=""
while read -r q_ins; do

        host="$(echo $q_ins | awk -F"@" '{print $2}')"
	# We ignore nodes in ICU or in au states
	if grep -q "$host" <<< "$icu_grp" || grep -q "$q_ins" <<< "$au_list"
	then
		 printf "SKIPPED: $host is found in ICU (@icu) OR in SGE (au) state.\n"
	else
        	ver_check="$(ssh "$host" '/opt/dice_host_utils/check_ver_mismatch.sh' < /dev/null)"
		
        	if [[ "$ver_check" != *"OK"* ]] # use OK it can catch nodes with broken SSH too
        	then
			found="${found}${q_ins}\n"
		fi
        fi
done <<< "$(echo "$todo_list")"

if [[ ! -z "$found" ]]
then
	printf "$found" > "$nf_probe_file"
	cat "$nf_probe_file"
fi

exit 0

