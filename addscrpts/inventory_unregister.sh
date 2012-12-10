#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""
output=""

out="$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@"${VI_SERVER}" vim-cmd vmsvc/unregister $1 2>&1)"
[ "${out}" = "" ] && exit 0

for outElements in ${out};
do
	 output="${output} ${outElements}"
done

echo ${output}

exit 1
