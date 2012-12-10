#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""
vmid=""

out="$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} vim-cmd vmsvc/getallvms | grep "vmx")"
for outElements in ${out};
do
	if [ ${outElements} = $1 ]
	then
		echo ${vmid}
		exit 0
	fi
	vmid=${outElements}
done
exit 1
