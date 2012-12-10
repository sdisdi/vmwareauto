#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""
outcmd=""
output=""

outcmd="$(sshpass -p "${VI_PASSWORD}" scp -o StrictHostKeyChecking=no ${CONFDIR}/esxiauto ${VI_USERNAME}@${VI_SERVER}:/tmp 2>&1)"
out=${out}${outcmd}
outcmd="$(sshpass -p "${VI_PASSWORD}" scp -o StrictHostKeyChecking=no ${CONFDIR}/esxiauto.pub ${VI_USERNAME}@$1:/tmp 2>&1)"
out=${out}${outcmd}
outcmd="$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@$1 'mkdir .ssh; cat /tmp/esxiauto.pub >> /.ssh/authorized_keys' 2>&1)"
out=${out}${outcmd}

for outElements in ${out};
do
	 output="${output} ${outElements}"
done

echo ${output}

exit 0
