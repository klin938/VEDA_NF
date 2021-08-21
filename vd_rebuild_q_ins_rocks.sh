#!/bin/bash

# DV-4

exec >> /tmp/vd_rebuild_q_ins_rocks.log
exec 2>&1

printf "#################### Started: $(date "+%Y.%m.%d-%H.%M.%S") ####################\n"

if [[ -z "$1" ]]
then
        printf "Usage: $0 FILE_QUEUE_INS\n"
        exit 2
fi

todo_list="$(cat $1)"

if [[ -z "$todo_list" ]]
then
        printf "INFO: todo_list is empty, Cannot find any queue instances from $1\n"
        exit 2
fi

# PADMIN-35
while IFS= read -r q_ins
do
	host="$(echo $q_ins | awk -F"@" '{print $2}')"

	rocks remove host partition "$host"
	rocks set host boot "$host" action=install
	# issue reboot cmd with nukeit to R2D2
	ssh "$host" 'echo "nukeit" > /root/reboot && touch /root/veda' < /dev/null
done < <(printf '%s\n' "$todo_list") # PADMIN-35

exit 0
