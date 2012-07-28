#!/bin/bash

# Lists the number of XCP/Xenserver Virtual Machines on each host
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 22, 2012

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
        echo "-d - shell debugging"
        echo "-h - this help text"
        echo ""
        exit
}

TMPFILE=$(mktemp)
VMLIST=$(xe vm-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
xe vm-list params=resident-on power-state=running | sed '/^$/d' | awk -F: '{count[$2]++}END{for(j in count) print j,count[j]}' > "$TMPFILE"
IFS=$'\n'
NAMELONGEST=0

while getopts :dh opt
do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))


setcolors
# Get longest HOST name
NAMELIST=$(xe host-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
for NAME in $NAMELIST
do
        if [[ ${#NAME} -gt $NAMELONGEST ]]
        then
                NAMELONGEST=${#NAME}
        fi
done


for LINE in $(cat $TMPFILE)
do
	HOSTUUID=$(echo $LINE | awk '{print $1}')
	HOSTLABEL=$(xe host-list uuid="$HOSTUUID" params=name-label --minimal)
	HOSTVMNUMS=$(echo $LINE | awk '{print $2}')
        LENGTH=${#HOSTLABEL}	
        (( NAMESPACES = $HOSTLONGEST - $LENGTH + 10 ))
        echo -ne "${cyan}$HOSTLABEL${off}"
        printf "%*s" "$NAMESPACES"
        echo -e "${blue}Running VMs:${off}${HOSTVMNUMS}" 
done

