#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin

VERSION="0.1"
SCRPNAME=`basename $0`

PWD="$(pwd)"
LIBDIR="${PWD}/lib"
CONFDIR="${PWD}/conf"
ADDSCRPDIR="${PWD}/addscrpts"
CONFILE="${CONFDIR}/vconfig"
DEFCOLORS="${LIBDIR}/define_colors"
FUNCTIONS="${LIBDIR}/functions"

. ${DEFCOLORS}
. ${FUNCTIONS}

case "$1" in
	"help"|"--help"|"-h")
		{ msg "${RED}Usage:${NC} Just execute ${SCRPNAME}" ; exit 1 ; }
	;;
esac

read -p "--> ESXi host fqdn or ip: " esxhost
export VI_SERVER="${esxhost}"

. ${CONFILE}

i=1
out=""
errMsg=""
eStatus=0

vmxList=$(${ADDSCRPDIR}/list_vmx.sh 2>&1)
eStatus=$?
errMsg=(grep -i error ${vmxList})
[ ${eStatus} -gt 0 ] && [ "${errMsg}" != "" ] && errmsg "Error executing listing of vmxs: ${vmxList}"

msg "Please choose guest:"
for guestRaw in ${vmxList}; do
	guestList=$(echo "${guestRaw}" | awk -F "/" '{print $6}')
	guestList=${guestList%%.vmx}
	msg "${i}: ${guestList}"
	let "i+=1"
done

read -p "--> GUEST: " guest
read -p "--> ACTION: (shutdown/on)?: " action

msg "Please confirm ACTION:${action} on GUEST:${guest}"
read -p "(y/n): " confirm

[ "${confirm}" = "n" ] && errmsg "Action was not confirmed! Exiting..."
[ "${confirm}" != "y" ] && errmsg "Wrong confirmation! Exiting..."

for guestVmx in ${vmxList}; do
	curGuest=$(echo "${guestVmx}" | awk -F "/" '{print $6}')
	curGuest=${curGuest%%.vmx}
	if [ "${curGuest}" = "${guest}" ]; then
		guestState=$(${ADDSCRPDIR}/getGuestState.sh "${guestVmx}" 2>&1)
		if [[ ("${guestState}" = "on") && ("${action}" = "shutdown") || ("${guestState}" = "off") && ("${action}" = "on") ]]; then
			vmid=$(${ADDSCRPDIR}/getVmId.sh "${curGuest}")
			if [ "${vmid}" != "" ]; then
				[ "${action}" = "on" ] && out=$(${ADDSCRPDIR}/startStopGuest.sh "${action}" "${vmid}") && msg "${out} ${curGuest}" && break
				vmTools=$(${ADDSCRPDIR}/checkVMwareTools.sh "${guestVmx}" 2>&1)
				case "${vmTools}" in
					1)
						out=$(${ADDSCRPDIR}/startStopGuest.sh "shutdown" "${vmid}")
						;;
					0)
						msg "Guest does not support soft shutdown. Could I use hard one?"
						read -p "(y/n): " yesNo
						[ "${yesNo}" = "y" ] && out=$(${ADDSCRPDIR}/startStopGuest.sh "off" "${vmid}")
						;;
					*)
						errmsg "Guest is not responding normally!"
						;;
				esac
				[ "${out}" != "" ] && msg "${out} ${curGuest} - DONE" || msg "${curGuest}: was not stopped!"
			else errmsg "Could not take vmid!"
			fi
		else errmsg "Guest state is already: ${action}"
		fi
	fi
done

[ "${out}" = "" ] && errmsg "Could not find guest!"

exit 0
