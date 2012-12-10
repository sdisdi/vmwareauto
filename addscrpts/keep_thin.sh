#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""
outcmd=""
output=""

outcmd=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} "vmkfstools -E /vmfs/volumes/datastore1/$1/$1.vmdk /vmfs/volumes/datastore1/$1/srcDisk.vmdk" 2>&1)
out=${out}${outcmd}
outcmd=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} "vmkfstools -i /vmfs/volumes/datastore1/$1/srcDisk.vmdk /vmfs/volumes/datastore1/$1/$1.vmdk -d thin" 2>&1)
out=${out}${outcmd}
outcmd=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} "rm -r /vmfs/volumes/datastore1/$1/srcDisk*" 2>&1)
out=${out}${outcmd}
[ "${out}" = "" ] && exit 0

for outElements in ${out};
do
	 output="${output} ${outElements}"
done

echo ${output}

exit 1
