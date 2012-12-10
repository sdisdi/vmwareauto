#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""
output=""
outElements=""

out=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} vim-cmd vmsvc/power.$1 $2 2>&1)
for outElements in ${out};
do
	 output="${output} ${outElements}"
done

echo ${output}

exit 0
