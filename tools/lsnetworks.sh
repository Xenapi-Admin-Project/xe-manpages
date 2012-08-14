#!/bin/bash

# Shows network information
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: August 4, 2012
# Version: 0.6
# Date: August 12, 2012
# Fixed but in vlan variables not resetting

setcolors()
{
	black='\e[30;47m'
	white='\e[37;47m'
    red='\e[0;31m'
    blue='\e[0;34m'
    cyan='\e[0;36m'
    off='\e[0m'
}

cecho ()                     
{
	MSG="${1}"       
	eval color=\$$2     
  	echo -ne "${color}"
  	echo -ne "$MSG"
  	echo -ne "${off}"                      
}

syntax()
{
        echo ""
        echo "Syntax: $(basename $0) [options]"
        echo "Options:"
        echo "-d - shell debugging"
        echo "-h - this help text"
        echo "-u - show UUIDs"
        echo ""
        exit
}

#Main
setcolors
while getopts :dhu opt
do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                u) UUID="yes" ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

OLDIFS="$IFS"
IFS=$'\n'

# arrays of items
NETUUIDS=( $(xe network-list params=uuid --minimal | sort | sed 's/,/\n/g') )
if [[ "$UUID" = "yes" ]] ;then
	NETNAMES=( $(xe network-list params=uuid --minimal | sort | sed 's/,/\n/g' ) )
else
	NETNAMES=( $(xe network-list params=name-label --minimal | sort | sed 's/,/\n/g') )
fi
if [[ "$UUID" = yes ]] ;then
	VMNAMES=( $(xe vm-list params=uuid is-control-domain=false --minimal | sort | sed 's/,/\n/g') )
else
	VMNAMES=( $(xe vm-list params=name-label is-control-domain=false --minimal | sort | sed 's/,/\n/g') )
fi
VLANUUIDS=( $(xe vlan-list --minimal | sort | sed 's/,/\n/g') )
BRIDENAMES=( $(xe network-list params=bridge --minimal | sort | sed 's/,/\n/g') )
TITLES=( 'Network' 'Bridge' 'VLAN' 'Virtual Machine' 'Device' )

MINSPACE="5"
NETNAMELONGEST="0"
NETUUIDLONGEST="0"
BRIDENAMELONGEST="0"
VMNAMELONGEST="0"
VMNAMESPACES="0"


# Get longest names in each column
for NAME in ${NETNAMES[@]} ${TITLES[0]} ;do
	if [[ "${#NAME}" -gt "${COLLONGEST[0]}" ]] ;then
		COLLONGEST[0]="${#NAME}"
	fi
done

# Get longest Bridge name column
for NAME in ${BRIDENAMES[@]} ${TITLES[1]} ;do
	if [[ "${#NAME}" -gt "${COLLONGEST[1]}" ]] ;then
		COLLONGEST[1]="${#NAME}"
	fi
done

# Get longest VLAN name column
if [[ "$UUID" = "yes" ]] ;then
	for NAME in ${VLANUUIDS[@]} ${TITLES[2]} ;do
		if [[ "${#NAME}" -gt "${COLLONGEST[2]}" ]] ;then
			COLLONGEST[2]="${#NAME}"
		fi
	done
else
	COLLONGEST[2]=3
fi

# Get longest VM name column
for NAME in ${VMNAMES[@]} ${TITLES[3]} ;do
	if [[ "${#NAME}" -gt "${COLLONGEST[3]}" ]] ;then
		COLLONGEST[3]="${#NAME}"
	fi
done

# Print headings
i=0
for TITLE in ${TITLES[@]}
do
	LENGTH=${#TITLE}	
    NAMESPACES=$(( ${COLLONGEST[$i]} + $MINSPACE - $LENGTH ))
	cecho "$TITLE" off
	printf "%*s" "$NAMESPACES" 	
	(( i++ ))
done
echo ""

for NETWORK in ${NETNAMES[@]}
do
	
	if [[ $UUID = "yes" ]] ;then
			NETUUID="$NETWORK"
	else
			NETUUID=$(xe network-list name-label="$NETWORK" --minimal)
	fi
	BRIDGE=$(xe network-param-get uuid=$NETUUID param-name=bridge)
	if [[ "$BRIDGE" == *xapi* ]] 
	then
		#see if there's a vlan associated
		VLANNUM=$(xe pif-list network-uuid="$NETUUID" params=VLAN --minimal)
		if [[ "$UUID" = "yes" ]] ;then
			VLANUUID=$(xe vlan-list tag="$VLANNUM" --minimal)
			VLAN="$VLANUUID"
		else
			VLAN="$VLANNUM"
		fi
	else
		VLAN=""
		VLANNUM=""
		VLANUUID=""
    fi    
    
    #echo the item followed by the correct number of spaces	
	cecho "$NETWORK" cyan ;	printf "%*s" "$(( ${COLLONGEST[0]} + $MINSPACE - ${#NETWORK} ))"  
	cecho "$BRIDGE"  cyan ; printf "%*s" "$(( ${COLLONGEST[1]} + $MINSPACE - ${#BRIDGE} ))" 
	cecho "$VLAN"    cyan ; printf "%*s" "$(( ${COLLONGEST[2]} + $MINSPACE - ${#VLAN} ))" 

	#Get list of vifs on network	
	i=0
	VIFVMLIST=$(xe vif-list network-uuid=$NETUUID params=vm-uuid --minimal | sed 's/,/\n/g')
	for VMUUID in $VIFVMLIST
	do
		#Get VM name-label
		if [[ "$UUID" = "yes" ]] ;then
			VMNAME[$i]="$VMUUID"
		else
			VMNAME[$i]=$(xe vm-list uuid=$VMUUID params=name-label --minimal)
		fi
		VMDEVNUM[$i]=$(xe vif-list vm-uuid=$VMUUID params=device --minimal )
		if [[ $i == 0 ]] ;then
			cecho "${VMNAME[0]}"  cyan ; printf "%*s" "$(( ${COLLONGEST[3]} + $MINSPACE - ${#VMNAME[0]} ))" 
			cecho "${VMDEVNUM[0]}" cyan
		else
			VMNAMESPACES=$(( ${COLLONGEST[0]} + $MINSPACE + ${COLLONGEST[1]} + $MINSPACE + ${COLLONGEST[2]} + $MINSPACE ))
			echo "" ; printf "%*s" "$VMNAMESPACES"	
			cecho "${VMNAME[$i]}" cyan
			printf "%*s" "$(( ${COLLONGEST[3]} + $MINSPACE - ${#VMNAME[$i]} ))" 
			cecho "${VMDEVNUM[$i]}" cyan
		fi
		(( i++ ))
	done
	echo ""
done

