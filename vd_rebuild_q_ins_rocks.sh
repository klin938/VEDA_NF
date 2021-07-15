#!/bin/bash

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

while read -r q_ins; do
	host="$(echo $q_ins | awk -F"@" '{print $2}')"

	rocks remove host partition "$host"
	rocks set host boot "$host" action=install
	ssh "$host" '/opt/dice_host_utils/reboot_q_ins_sge.sh' < /dev/null
done <<< "$(echo "$todo_list")"

exit 0
