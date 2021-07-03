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

while read -r q_ins; do
	host="$(echo $q_ins | awk -F"@" '{print $2}')"

	rocks remove host partition "$host"
	ssh "$host" 'sh /root/nukeit.sh' < /dev/null

	rocks set host boot "$host" action=install
	ssh "$host" 'shutdown -r now' < /dev/null
done <<< "$(echo "$todo_list")"

exit 0
