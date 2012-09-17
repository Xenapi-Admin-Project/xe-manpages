#!/bin/bash

# Shows network information
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: August 4, 2012
# Version: 0.6
# Date: August 12, 2012
# Fixed but in vlan variables not resetting
# Version: 0.7
# Date: August 19, 2012
# Changed wording for VM device
# Version: 0.8
# Date: September 14th, 2012
# rewrote using getcolwidth, printspaces and sort_netnames
# addes CSV output
# Version: 0.9
# Date: September 15th, 2012
# Changed to MODE=uuid. This will allow for future modes.

setup()
{
	setcolors	
	VERSION="0.9"
	MINSPACE="5"
	MODE="name"
	IFS=$'\n'
}

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
		echo "$(basename $0) $VERSION"
        echo ""
        echo "Syntax: $(basename $0) [options]"
        echo "Options:"
        echo "-d - shell debugging"
        echo "-c - output comma seperated values"
        echo "-h - this help text"
        echo "-u - show UUIDs"
        echo "-n - show Names (Default)"
        echo ""
        exit
}

#get width of columns
getcolwidth()
{
	#get longest item in array
	array=( "$@" )
	i=0
	LONGEST="0"
	IFS=$'\n'
	for ITEM in ${array[@]} ;do
		if [[ "${#ITEM}" -gt "$LONGEST" ]] ;then
			LONGEST="${#ITEM}"
		fi
	done
	echo "$LONGEST"
}

sort_netnames()
{   
	local MAX=$((${#NETNAMES[@]} - 1))
    while ((MAX > 0)) ;do
       	local i=0 
        while ((i < MAX)) ;do
			local j=$((i + 1))
			if expr "${NETNAMES[$i]}" \> "${NETNAMES[$j]}" >/dev/null
			then
                local t=${NETNAMES[$i]}
                local u=${NETUUIDS[$i]}
                local v=${BRIDGENAMES[$i]}
                local w=${VLAN[$i]}
                NETNAMES[$i]=${NETNAMES[$j]}
                NETUUIDS[$i]=${NETUUIDS[$j]}
                BRIDGENAMES[$i]=${BRIDGENAMES[$j]}
                VLAN[$i]=${VLAN[$j]}
                NETNAMES[$j]=$t
                NETUUIDS[$j]=$u
                BRIDGENAMES[$j]=$v
                VLAN[$j]=$w
            fi
            ((i++))
        done
        ((MAX--))
    done
}

printspaces()
{
	# arg 1 - the longest item in the column (integer)
	# arg 2 - the length of the item ie. ${#VAR} (integer)
	COLUMN="$1"
	ITEM="$2"
	
	if [[ "$CSV" = "yes" ]] ;then
		echo -ne ","
	else
		printf "%*s" "$(( $COLUMN + $MINSPACE - $ITEM ))"
	fi 
}


setup

# Get cli options
while getopts :dhcnu opt
do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                c) CSV="yes" ;;
                u) MODE="uuid" ;;
                n) MODE="name" ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

# Set TITLE array
case "$MODE" in
	"uuid") TITLES=( 'Network UUID' 'Bridge' 'VLAN UUID' 'Virtual Machine UUID' 'VM Device' ) ;;
	"name") TITLES=( 'Network' 'Bridge' 'Vlan Tag' 'Virtual Machine' 'VM Device' ) ;;
esac

# Populate ALL arrays for Network UUIDs, Bridge names VLAN Tags and UUIDs, VM names and VMUUIDs
NETUUIDS=( $(xe network-list params=uuid --minimal | sed 's/,/\n/g') ) 
for i in $(seq 0 $(( ${#NETUUIDS[@]} - 1 )) ) ;do
	BRIDGENAMES[$i]=$(xe network-list uuid="${NETUUIDS[$i]}" params=bridge --minimal | sed 's/,/\n/g')
	if [[ "${BRIDGENAMES[$i]}" == *xapi* ]] ;then
		# If bridge has a VLAN, get it's tag or uuid
		VLANNUM=$(xe pif-list network-uuid="${NETUUIDS[$i]}" params=VLAN --minimal)
		if [[ ! -z "$VLANNUM" ]] ;then
			if [[ ! "$VLANNUM" = '-1' ]] ;then
				VLANUUID=$(xe pif-list VLAN="$VLANNUM" params=uuid --minimal)
			else
				VLANUUID=""
			fi
		fi
	fi
	
	# For now just get all VM UUID/Names that will be printed later and assign them to an array for getcolwidth
	VMUUIDS+=( $(xe vif-list network-uuid="${NETUUIDS[$i]}" params=vm-uuid --minimal | sed 's/,/\n/g' ) )
	case "$MODE" in
		"uuid") 
			NETNAMES[$i]=${NETUUIDS[$i]}
			VMNAMES+=( "${VMUUIDS[@]}" )
			VLAN[$i]="$VLANUUID"
		;;
		"name")
			NETNAMES[$i]=$(xe network-list uuid="${NETUUIDS[$i]}" params=name-label --minimal)
			for VMUUID in $VMUUIDS ;do
				VMNAMES+=( $(xe vm-list uuid="$VMUUID" params=name-label --minimal) )
			done
			VLAN[$i]="$VLANNUM"
		;;
	esac
done

# bubble sort the network names in alphabetical order
sort_netnames

# Get the length of each column and store it in COLLONGEST[]
case "$MODE" in
	"uuid") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${NETUUIDS[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${BRIDENAMES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${VLAN[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${VMUUIDS[@]}")
	 ;;
	"name") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${NETNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${BRIDENAMES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${VLAN[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${VMNAMES[@]}")
	 ;;
esac

# Print column headings
for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
	cecho "${TITLES[$i]}" off ; printspaces "${COLLONGEST[$i]}" "${#TITLES[$i]}"
done
echo ""

# Main loop - display Network and Bridge names and VLAN tag/uuid. 
# Get vm names/uuids and display
for i in $(seq 0 $(( ${#NETUUIDS[@]} - 1 )) ) ;do
	cecho "${NETNAMES[$i]}" cyan ;	  printspaces "${COLLONGEST[0]}" "${#NETNAMES[$i]}" 
	cecho "${BRIDGENAMES[$i]}" blue ; printspaces "${COLLONGEST[1]}" "${#BRIDGENAMES[$i]}" 
	cecho "${VLAN[$i]}" blue ;	      printspaces "${COLLONGEST[2]}" "${#VLAN[$i]}" 
	
	#Get list of vifs on network
	j=0
	VMUUIDS=$(xe vif-list network-uuid=${NETUUIDS[$i]} params=vm-uuid --minimal | sed 's/,/\n/g' | sort)
	if [[ -z $VMUUIDS && "$CSV" = "yes" ]] ;then
		echo -ne ",,"
	fi
	for VMUUID in $VMUUIDS
	do
		#Get VM name-label
		case "$MODE" in
			"uuid") VM="$VMUUID" ;;
			"name") VM=$(xe vm-list uuid="$VMUUID" params=name-label --minimal) ;;
		esac
		VMDEVNUM=$(xe vif-list vm-uuid="$VMUUID" network-uuid=${NETUUIDS[$i]} params=device --minimal )
		if [[ "$j" -eq "0" ]] ;then
			cecho "${VM}"  blue ; printspaces "${COLLONGEST[3]}" "${#VM}" 
			cecho "$VMDEVNUM" blue
		else
			if [[ "$CSV" = "yes" ]] ;then
				echo "" ; echo -ne ",,,"
			else
				COLSPACES=$(( ${COLLONGEST[0]} + $MINSPACE + ${COLLONGEST[1]} + $MINSPACE + ${COLLONGEST[2]} + $MINSPACE ))
				echo "" ; printf "%*s" "$COLSPACES"
			fi
			cecho "${VM}" blue ; printspaces "${COLLONGEST[3]}" "${#VM}"
			cecho "${VMDEVNUM}" blue
		fi
		(( j++ ))
	done
	echo ""
done

