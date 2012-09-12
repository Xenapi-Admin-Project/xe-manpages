#!/bin/bash

# Lists the load on each Host CPU core
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 22, 2012

IFS=$'\n'
TIMER=5 #seconds

setcolors()
{
        red='\e[0;31m'
        blue='\e[0;34m'
        cyan='\e[0;36m'
        off='\e[0m'
}

syntax()
{
        echo ""
        echo "Syntax: $(basename $0) [options]"
        echo "Options:"
	echo "-f - continuous updates"
        echo "-d - shell debugging"
        echo "-h - this help text"
        echo ""
        exit
}

showcpuinfo()
{

	#Loop through hosts
	# for each host loop through CPUs, get number and load.
	HOSTNAMELIST=$(xe host-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
	for HOST in $HOSTNAMELIST
	do
	        LENGTH=${#HOSTLABEL}	
        	(( NAMESPACES = $HOSTLONGEST - $LENGTH + 10 ))
        	echo -e "${cyan}$HOST:${off}"
		HOSTUUID=$(xe host-list params=uuid --minimal name-label=$HOST)
		for CPU in $(xe host-cpu-list host-uuid=$HOSTUUID params=number --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
		do
			CPUUUID=$(xe host-cpu-list host-uuid="$HOSTUUID" number="$CPU" params=uuid --minimal)
			LOAD=$(xe host-cpu-param-get uuid=$CPUUUID param-name=utilisation)
        		printf "%*s" "$NAMESPACES"
        		echo -e "${blue}CPU:${off}${CPU}     ${blue}LOAD:${off}$LOAD" 
		done
	done

}


while getopts :fdh opt
do
        case $opt in
		f) FOLLOW=yes ;;
                d) set -x ;;
                h) syntax ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

setcolors

# Get longest HOST name
NAMELONGEST=0
NAMELIST=$(xe host-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
for NAME in $NAMELIST
do
        if [[ ${#NAME} -gt $NAMELONGEST ]]
        then
                NAMELONGEST=${#NAME}
        fi
done

clear
if [ "$FOLLOW" = "yes" ] 
then
	while true
	do
		showcpuinfo
		sleep "$TIMER"
		clear
	done
else
	showcpuinfo
fi

