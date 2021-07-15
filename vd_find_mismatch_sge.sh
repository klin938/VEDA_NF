#!/bin/bash

# Usage: $0 [QUEUE] [NF_CHANNEL_FILE_DIR]

# RETURN:  number of mismatch nodes or 0
# PRODUCE: nf_probe_mismatch contains just the list of mismatch nodes used by Nextflow
#          vd_find_mismatch_sge.log contains all output inc nf_probe_mismatch content

exec >> /tmp/vd_find_mismatch_sge.log
exec 2>&1

printf "#################### Started: $(date "+%Y.%m.%d-%H.%M.%S") ####################\n"

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
	# We ignore nodes in ICU
	if grep -q "$host" <<< "$icu_grp"
	then
		printf "SKIPPED: $host is found in ICU (@icu).\n"
	elif grep -q "$q_ins" <<< "$au_list"
	then    # We inc (au) state nodes in case of kickstarting or rebooting
		printf "UNKNOWN: $host is in SGE (au) state, counted as mismatch.\n"
		found="${found}${q_ins}\n"
	else
        	ver_check="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$host" '/opt/dice_host_utils/check_ver_mismatch.sh' < /dev/null)"
		
        	if [[ "$ver_check" != *"OK"* ]] # use OK it can catch nodes with broken SSH too
        	then
			found="${found}${q_ins}\n"
		fi
        fi
done <<< "$(echo "$todo_list")"

if [[ ! -z "$found" ]]
then
	printf "$found" > "$nf_probe_file"
	count="$(cat "$nf_probe_file" | wc -l)"
	printf "Number of nodes mismatch: $count\n"
	cat "$nf_probe_file"
	exit $count
fi

exit 0

