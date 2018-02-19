#!/bin/bash

# MD -- checker wszystkiego, co zostanie podane jako parametr $1

DATA=$(date "+%F %T:")
HOST=$(hostname)
#
DATFILE=io_${1}.dat

EMAILTO=addres@provider
EMAILFROM=address@provider

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
		echo "$DATA ${1} bez zmian, restartuje proces"
		kill $PID && /etc/init.d/${1} restart
		sleep 2
		if [ -z $(pgrep -f "/usr/sbin/${1}") ]; then
			echo "$DATA Brak procesu ${1} po restarcie daemona"
			send_mail "$DATA Brak procesu ${1} po restarcie daemona!"
			exit 1
		fi
		MODIFY_T=$(stat -c %Z /var/tmp/${DATFILE})
		PRESENT_T=$(date +%s)
		if [ $(($PRESENT_T - $MODIFY_T)) -le 400 ]; then
			echo "$DATA 5 min temu proces ${1} byl restartowany!"
			send_mail "$DATA 5 min temu proces ${1} byl restartowany!"
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
	echo "$DATA Brak procesu ${1}. Exit"
	exit 1
fi

STAT_IO=$(cat /proc/$PID/io)

if [ -s /var/tmp/${DATFILE} ]; then
	do_check
else
	echo $STAT_IO > /var/tmp/${DATFILE}
fi

# EOF

