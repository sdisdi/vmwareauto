#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

. ${CONFILE}

out=""

out=$(sshpass -p "${VI_PASSWORD}" ssh -o StrictHostKeyChecking=no ${VI_USERNAME}@${VI_SERVER} "vim-cmd solo/registervm /vmfs/volumes/datastore1/$1/$1.vmx" 2>&1)
[ "${out}" = "" ] && exit 1
echo ${out}

exit 0
