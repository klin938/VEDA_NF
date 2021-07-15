#!/bin/bash

# Record the result to the main progress log
LOG="/tmp/vd_progress_check_sge.log"

q="${1:-short.q}"
survival_rate="${2:-0.50}"

# num of disabled divided by all

count_all="$(qstat -f -q $q | grep $q | wc -l)"
count_disabled="$(qstat -f -q $q -qs d | grep $q | wc -l)"
current_rate="$(echo "scale=2; $count_disabled/$count_all" | bc)"

if (( $(echo "$current_rate <= $survival_rate" | bc -l) )); then
	printf "Survival: OK  [ All: $count_all | Disabled: $count_disabled | Ratio: $current_rate ]\n" > nf_probe_survive
	cat nf_probe_survive >> "$LOG"
else
	printf "Survival: BAD [ All: $count_all | Disabled: $count_disabled | Ratio: $current_rate ]\n" >> "$LOG"
fi


