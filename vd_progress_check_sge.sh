#!/bin/bash

q="${1:-short.q}"
completed_rate="${2:-1}"

current_time="$(date "+%Y.%m.%d-%H.%M.%S")"

count_all="$(qstat -f -q $q | grep $q | wc -l)"
count_mismatch="$(./vd_find_mismatch_sge.sh $q | wc -l)"
count_completed="$(( count_all - count_mismatch ))"
current_rate="$(echo "scale=2; $count_completed/$count_all" | bc)"

if (( $(echo "$current_rate < $completed_rate" | bc -l) )); then
	printf "BAD [ $current_time | All: $count_all | Completed: $count_completed | Progress: $current_rate ]\n"
else
	printf "OK [ $current_time | All: $count_all | Completed: $count_completed | Progress: $current_rate ]\n"
fi


