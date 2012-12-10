#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

PWD=$(pwd)
CONFDIR="${PWD}/conf"
CONFILE="${CONFDIR}/vconfig"

/usr/bin/vmware-cmd --config ${CONFILE} $1 getstate | awk '{print $3}' || exit 1
exit 0
