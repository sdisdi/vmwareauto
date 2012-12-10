#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

/usr/bin/vmware-cmd --config ${CONFILE} -l | grep vmx || exit 1
exit 0
