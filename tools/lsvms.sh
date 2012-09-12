#!/bin/bash

# Lists XCP/Xenserver Virtual Machines one per line with uuid and host
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: June 27, 2012

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

VMLIST=$(xe vm-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
HOSTLIST=$(xe host-list params=name-label --minimal)
IFS=$'\n'
VMLONGEST=0

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
for VM in $VMLIST
do
	CD=$(xe vm-list name-label="$VM" params=is-control-domain --minimal)
        if [[ $CD = "true" ]];then
                continue
        fi

        if [[ ${#VM} -gt $VMLONGEST ]]
        then
                VMLONGEST=${#VM}
        fi
done

for VM in $VMLIST
do
	CD=$(xe vm-list name-label="$VM" params=is-control-domain --minimal)
	if [[ $CD = "true" ]];then
		continue
	fi
        LENGTH=${#VM}
        VMUUID=$(xe vm-list name-label="$VM" --minimal)
	VMSTATUS=$(xe vm-list params=power-state name-label=${VM} --minimal)
	HOSTUUID=$(xe vm-list uuid=$VMUUID params=resident-on --minimal)
	HOSTLABEL=$(xe host-list uuid=$HOSTUUID params=name-label --minimal)	
        (( VMSPACES = $VMLONGEST - $LENGTH + 10 ))
        echo -ne "${cyan}$VM${off}"
        printf "%*s" "$VMSPACES"
        echo -e "${red}($VMSTATUS)${off}  ${blue}uuid:${off}$VMUUID  ${blue}host:${off}${HOSTLABEL%%.*}"
done

# alternate strategy - maybe I'll use it later...
# echo "VM ($VMSTATUS) $UUID "     >> "$TMPDIR/classlist"
# (printf "NAME STATUS UUID \n" ; cat "$TMPDIR/classlist" | sort -k 1) | column -t
