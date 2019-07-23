#!/bin/bash
################################################################################
#          Copyright 2019 Aditya Sahu <asahu@infoblox.com>                     #
#   For any issues/suggestions please write to asahu@infoblox.com              #
################################################################################

trap "rm -f GRID-DETAILS.$$" EXIT
trap "rm -f  AUTOSCALE-METHODS.$$" EXIT
PLAYBOOK="/root/autoscale_ansible/ansible_playbook_autoscaling.yaml"
dialog --title "NIOS Autoscaling on OpenStack using Ansible" --yesno "Please hit on yes to initiate NIOS autoscale." 8 78



if  [ $? = 0 ]
        then
                dialog --title "Please select your autoscale method" --menu "Please choose an option" 25 100 16 \
"1."  "NIOS will autoscale based on incoming DNS queries." \
"2."  "NIOS will autoscale based on Grid CPU and Memory utilization." 2> AUTOSCALE-METHODS.$$
                read METHOD < AUTOSCALE-METHODS.$$
                        case $METHOD in
                        1.)echo -e '\E[32' "You have selected"-->" NIOS autoscaling based on DNS queries"
                                sleep 1
                                clear
                          dialog --backtitle "NIOS will autoscale based on DNS queries" --title "Please enter following Grid details" \
--form "\nInfoblox" 25 60 16 \
"DNS-Member IPv4 Address:"       1 1 "" 1 30 25 30 \
"SNMP Community String:"         2 1 "" 2 30 25 30 \
"Scale up Threshold(QPS):"       3 1 "" 3 30 25 30 \
"Cache hit ratio(%):"            4 1 "" 4 30 25 30 \
"Member Count:"                  5 1 "" 5 30 25 30 \
2>GRID-DETAILS.$$

DNS_Member_IP="$(cat GRID-DETAILS.$$ | head -1)"
COMMUNITY_STRING="$(cat GRID-DETAILS.$$ |head -2|tail -1)"
SCALE_UP_THRESHOLD="$(cat GRID-DETAILS.$$ |tail -3 |head -1)"
CACHE_HIT_RATIO="$(cat GRID-DETAILS.$$ |tail -2 |head -1)"
MEMBER_COUNT="$(cat GRID-DETAILS.$$ |tail -1)"

sleep 1

dialog --backtitle "NIOS will autoscale based on DNS queries" --title "Please verify your Grid details" \
--form "\n" 25 60 16 \
"DNS-Member IPv4 Address:"       1 1 " "$DNS_Member_IP" " 1 30 25 30 \
"SNMP Community String:"         2 1 " "$COMMUNITY_STRING" " 2 30 25 30 \
"Scale up Threshold(QPS):"       3 1 " "$SCALE_UP_THRESHOLD" " 3 30 25 30 \
"Cache hit ratio(%):"            4 1 " "$CACHE_HIT_RATIO" " 4 30 25 30 \
"Member Count:"                  5 1 " "$MEMBER_COUNT" " 5 30 25 30 \
2>GRID-DETAILS.$$

##Assisning QPS value and Cache Hit Ratio value
DNS_QPS=`snmpget -v 2c -c $COMMUNITY_STRING $DNS_Member_IP 1.3.6.1.4.1.7779.3.1.1.3.1.6.0 -Ovq`
CACHE_HIT_RATIO=`snmpget -v 2c -c $COMMUNITY_STRING $DNS_Member_IP 1.3.6.1.4.1.7779.3.1.1.3.1.5.0 -Ovq`


##Calculating if the QPS value is more than the defined value
##Calculating if the CHR is less than the defined value

if [ $DNS_QPS -ge $SCALE_UP_THRESHOLD ] && [ $CACHE_HIT_RATIO -lt "98" ]
     then
     dialog --title "Attention" --msgbox  "DNS QPS surge and low CHR detected. We will now monitor the Grid for 40 seconds" 10 40
     declare -a QPS_ARRAY='()'
     TOTAL_QPS=0

     for i in {1..10}
     do
     QPS_ARRAY+=( "$(snmpget -v 2c -c $COMMUNITY_STRING $DNS_Member_IP 1.3.6.1.4.1.7779.3.1.1.3.1.6.0 -Ovq)" )
     sleep 2
     let TOTAL_QPS="$TOTAL_QPS + $i"
     done

     QPS_SUM=0

     for i in ${QPS_ARRAY[@]}
     do
     let QPS_SUM="QPS_SUM + $i"
     done


if [ $(($QPS_SUM / 10)) -ge $SCALE_UP_THRESHOLD ]
     then
     echo  -e "\x1b[95;19m *** Persistent DNS QPS surge and low CHR detected. We will now autoscale *** \x1b[m"
     ansible-playbook $PLAYBOOK
     if [ $? -eq 0 ]
     then
     echo  -e "\x1b[95;19m *** We have deployed a new vNIOS member *** \x1b[m"
fi

     exit
     fi

     else
     clear
     echo "We didnot detect DNS QPS surge and low CHR. Exiting"
     exit
fi
;;

                        2.) echo -e "\x1b[45;19m *** You have selected--> NIOS autoscaling based on CPU and Memory utilization *** \x1b[m";;
                esac
        exit
fi
