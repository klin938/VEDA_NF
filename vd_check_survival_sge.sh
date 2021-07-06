#!/bin/bash

q="${1:-short.q}"
survival_rate="${2:-0.50}"

# num of disabled divided by all

count_all="$(qstat -f -q $q | grep $q | wc -l)"
count_disabled="$(qstat -f -q $q -qs d | grep $q | wc -l)"
current_rate="$(echo "scale=2; $count_disabled/$count_all" | bc)"

if (( $(echo "$current_rate <= $survival_rate" | bc -l) )); then
	printf "OK [ All: $count_all | Disabled: $count_disabled | Rate: $current_rate ]\n"
else
	printf "BAD [ All: $count_all | Disabled: $count_disabled | Rate: $current_rate ]\n"
fi


