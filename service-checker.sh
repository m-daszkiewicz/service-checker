#!/bin/bash

# check service status and restart if necessary

# usage: $0 <service name>

DATA=$(date "+%F %T:")
HOST=$(hostname)
#
DATFILE=io_${1}.dat

EMAILTO=addres@provider
EMAILFROM=address@provider

# below code needs to bechanged to support other mtas, leaving as-is for now
function send_mail
{
    ssmtp ${EMAILFROM} <<.
    To: ${EMAILTO}
    Subject: ${1} problem

$1
.
}

function do_check
{
	cmp -s /var/tmp/${DATFILE} <(echo $STAT_IO)
	if [ "$(echo $?)" == "0" ]; then
		echo "$DATA ${1} did not change, restarting process"
		kill $PID && /etc/init.d/${1} restart
		sleep 2
		if [ -z $(pgrep -f "/usr/sbin/${1}") ]; then
			echo "$DATA no process ${1} after daemon restart"
			send_mail "$DATA no process ${1} after daemon restart!"
			exit 1
		fi
		MODIFY_T=$(stat -c %Z /var/tmp/${DATFILE})
		PRESENT_T=$(date +%s)
		if [ $(($PRESENT_T - $MODIFY_T)) -le 400 ]; then
			echo "$DATA 5 minutes ago ${1} was restarted!"
			send_mail "$DATA 5 minutes ago ${1} was restarted!"
		fi
		echo $STAT_IO > /var/tmp/$DATFILE
		exit 0
	fi	
	echo $STAT_IO > /var/tmp/$DATFILE
}

# MAIN

PID=$(pgrep -f "${1}"|head -1)
echo "PID: $PID"
if [ -z "$PID" ]; then
	echo "$DATA No process ${1}. Exit"
	exit 1
fi

STAT_IO=$(cat /proc/$PID/io)

if [ -s /var/tmp/${DATFILE} ]; then
	do_check
else
	echo $STAT_IO > /var/tmp/${DATFILE}
fi

# EOF

