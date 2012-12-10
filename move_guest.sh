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
		{ msg "${RED}Usage:${NC} Just execute ${SCRPNAME} and follow the instructions" ; exit 1 ; }
	;;
esac

read -p ">>> SOURCE ESXi host fqdn or ip: " srcesx
export VI_SERVER="${srcesx}"
read -p ">>> DESTINATION ESXi host fqdn or ip: " dstesx

[ "${srcesx}" = "${dstesx}" ] && errmsg "SOURCE and DESTINATION can not be the same host! Exiting..."

. ${CONFILE}

i=1
out=""
errMsg=""
eStatus=0
invreg=""
invunreg=""
vmxList=""
guestFol=""
findVM=false
inid=""

vmxList=$(${ADDSCRPDIR}/list_vmx.sh 2>&1)
eStatus=$?
errMsg=(grep -i error ${vmxList})
[ ${eStatus} -gt 0 ] && [ "${errMsg}" != "" ] && errmsg "Error executing listing of vmxs: ${vmxList}"

msg "Please choose guest for moving:"
for guestRaw in ${vmxList}; do
	guestList=$(echo "${guestRaw}" | awk -F "/" '{print $6}')
	guestList=${guestList%%.vmx}
	msg "${i}: ${guestList}"
	let "i+=1"
done

read -p ">>> GUEST: " guest

##!!!CHECK destination disk space and resources!!!!!!

warnmsg "Please confirm ACTION:move with the following details"
msg "SOURCE ESXi: ${srcesx}"
msg "GUEST: ${guest}"
msg "DESTINATION ESXi: ${dstesx}"
read -p "(y/n): " confirm

[ "${confirm}" = "n" ] && errmsg "Action was not confirmed! Exiting..."
[ "${confirm}" != "y" ] && errmsg "Wrong confirmation! Exiting..."

i=1
strTime=$(date +%s)
for guestVmx in ${vmxList}; do
	curGuest=$(echo "${guestVmx}" | awk -F "/" '{print $6}')
	curGuest=${curGuest%%.vmx}
	if [ "${curGuest}" = "${guest}" ]; then
		vmid=$(${ADDSCRPDIR}/getVmId.sh "${curGuest}")
		[ "${vmid}" = "" ] && errmsg "Could not take vmid!"
		guestState=$(${ADDSCRPDIR}/getGuestState.sh "${guestVmx}" 2>&1)
		if [ "${guestState}" = "on" ]; then
			msg "GUEST state is: power on. SHUTTING it down..."
			vmTools=$(${ADDSCRPDIR}/checkVMwareTools.sh "${guestVmx}" 2>&1)
			case "${vmTools}" in
				1)
					out=$(${ADDSCRPDIR}/startStopGuest.sh "shutdown" "${vmid}")
					;;
				0)
					msg "Guest does not support soft shutdown. Could I use hard one?"
					read -p "(y/n): " yesNo
					if [ "${yesNo}" = "y" ]; then
						out=$(${ADDSCRPDIR}/startStopGuest.sh "off" "${vmid}")
					else errmsg "${guest}: was not stopped! Please stop it manually and try again."
					fi
					;;
				*)
					errmsg "Guest is not responding normally!"
					;;
			esac
			msg "SHUTTING down..."
			sleep 30
			for i in 1 2 3 4 5; do 
				guestState=$(${ADDSCRPDIR}/getGuestState.sh "${guestVmx}" 2>&1)
				[ "${guestState}" = "off" ] && break
				sleep 30
			done
			if [ "${guestState}" != "off" ]; then
				errmsg "${guest}: was not stopped! Please stop it manually and try again."
			else    msg "SHUTTING down... - DONE"
			fi
		else msg "GUEST state is: power off"
		fi

		timemsg $((($(date +%s) - ${strTime})/60))
		msg "REMOVING from inventory..."
		invunreg=$(${ADDSCRPDIR}/inventory_unregister.sh "${vmid}" 2>&1)
		vmxList=$(${ADDSCRPDIR}/list_vmx.sh 2>&1)
		for guestRaw in ${vmxList}; do
			guestList=$(echo "${guestRaw}" | awk -F "/" '{print $6}')
			guestList=${guestList%%.vmx}
			[ "${guestList}" = "${guest}" ] && errmsg "Could not remove guest from inventory!"
		done
		msg "REMOVING from inventory... - DONE"

		timemsg $((($(date +%s) - ${strTime})/60))
		msg "COPYING guest..."
		msg "Please wait, this operation could be long!"
		guestFol=$(echo ${guestVmx} | awk -F '/' '{print $1"/"$2"/"$3"/"$4"/"$5}')
		out=$(${ADDSCRPDIR}/keys.sh "${dstesx}" 2>&1)
		[ "${out}" != "" ] && msg "COPYING keys details: ${out}"
		out=$(${ADDSCRPDIR}/scp_guest.sh "${guestFol}" "${dstesx}" 2>&1)
		[ "${out}" != "" ] && msg "COPYING VM details: ${out}"
		msg "COPYING guest... - DONE"
		
		export VI_SERVER="${dstesx}"		

		timemsg $((($(date +%s) - ${strTime})/60))
		msg "CONVERTING guest..."
		out=$(${ADDSCRPDIR}/keep_thin.sh "${guest}" 2>&1)
		[ "${out}" != "" ] && msg "CONVERTING VM details: ${out}"
		msg "CONVERTING guest... - DONE"

		timemsg $((($(date +%s) - ${strTime})/60))
		msg "ADDING to inventory..."
		inid=$(${ADDSCRPDIR}/inventory_register.sh "${guest}" 2>&1)
		[ "${inid}" = "" ] && errmsg "Could not get new VM id!"
		msg "ADDING to inventory... - DONE"

		timemsg $((($(date +%s) - ${strTime})/60))
		msg "STARTING VM..."
		${ADDSCRPDIR}/startStopGuest.sh "on" "${inid}" &
		out=$(${ADDSCRPDIR}/inventory_move_answer.sh "${inid}")
		[ "${out}" != "" ] && errmsg "Could not start VM: ${out}"
		msg "STARTING VM... - DONE"

		timemsg $((($(date +%s) - ${strTime})/60))
		findVM=true
		msg "MOVING of ${guest} was successfully :)"
		break
	fi
done

[ ! ${findVM} ] && errmsg "Could not find ${guest}!"

exit 0
