#!/bin/bash

TIME=10
TIME_RES=1
PING_TIMEOUT=0.1
TEST_SERVER_V6=
TEST_SERVER_V6_2=
TEST_SERVER_V4=
LOG_DIR=/home/user/tun_log
INTERFACE=wg1

fw(){
        mkdir -p $LOG_DIR/`date +%Y-%m`/`date +%d`
        echo -e "`date +%H:%M:%S`\t$1" >> $LOG_DIR/`date +%Y-%m`/`date +%d`/`date +%H`.txt
}

trap 'systemctl stop radvd' EXIT

while :
do
ping -I $INTERFACE -W$PING_TIMEOUT -c1 $TEST_SERVER_V6
if [ "$?" -eq "0" ]; then
	systemctl start radvd
	sleep $TIME
else
	ping -I $INTERFACE -W$PING_TIMEOUT -c1 $TEST_SERVER_V6_2
	if [ "$?" -eq "0" ]; then
		systemctl start radvd
		sleep $TIME
	else
		fw "WG RESTART"
		systemctl restart wg-quick@$INTERFACE.service
		sleep $TIME_RES
		ping -W$PING_TIMEOUT -c1 $TEST_SERVER_V4
		if [ "$?" -ne "0" ]; then
			fw "ISP"
		fi
		ping -I $INTERFACE -W$PING_TIMEOUT -c1 $TEST_SERVER_V6
		if [ "$?" -ne "0" ]; then
			fw "RADVD STOP"
			systemctl stop radvd
		fi
	fi
fi
done
