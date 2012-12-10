#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""
output=""

sleep 10

msgid=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} "vim-cmd vmsvc/message $1 | grep message | awk '{print \$4}' | awk -F : '{print \$1}'" 2>&1)
out=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} "vim-cmd vmsvc/message $1 ${msgid} 1" 2>&1)
[ "${out}" = "" ] && exit 0
echo ${out}

exit 1
