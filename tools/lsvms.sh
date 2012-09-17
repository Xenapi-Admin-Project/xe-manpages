#!/bin/bash

# Lists XCP/Xenserver Virtual Machines one per line with uuid and host
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: June 27, 2012
# Version: 0.6
# Date: Sept 15, 2012
# Complete rewrite using printspaces, sort_vmnames and getcolwidth
# Now provides four output MODES - name, uuid. mixed and both
# Also provides CSV output

setup()
{
	setcolors
	IFS=$'\n'	
	MINSPACE="5"
	MODE="mixed"
}

#give names to ansi sequences
setcolors()
{
	black='\e[30;47m'
	white='\e[37;47m'
    red='\e[0;31m'
    blue='\e[0;34m'
    cyan='\e[0;36m'
    off='\e[0m'
}

#color echo
cecho ()                     
{
	MSG="${1}"       
	if [ -z $2 ] ;then
		color="white"
	else
		eval color=\$$2
	fi     
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
        echo "-c - output comma seperated values"
        echo "-u - shows VM UUID, Status, Host UUID"
        echo "-b - shows VM Name, Status, VMUUID, Host Name and Host UUID"
        echo "-n - shows VM Name, Status and Hostname"
        echo "-m - shows VM Name, Status, VM UUID and Hostname"
        echo "-h - this help text"
        echo ""
        exit
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

sort_vmnames()
{   
	local MAX=$((${#VMNAMES[@]} - 1))
    while ((MAX > 0)) ;do
       	local i=0 
        while ((i < MAX)) ;do
			local j=$((i + 1))
			if expr "${VMNAMES[$i]}" \> "${VMNAMES[$j]}" >/dev/null
			then
                local t=${VMNAMES[$i]}
                local u=${VMUUIDS[$i]}
                local v=${STATES[$i]}
                local w=${HOSTUUIDS[$i]}
                local x=${HOSTNAMES[$i]}
                VMNAMES[$i]=${VMNAMES[$j]}
                VMUUIDS[$i]=${VMUUIDS[$j]}
                STATES[$i]=${STATES[$j]}
                HOSTUUIDS[$i]=${HOSTUUIDS[$j]}
                HOSTNAMES[$i]=${HOSTNAMES[$j]}
                VMNAMES[$j]=$t
                VMUUIDS[$j]=$u
                STATES[$j]=$v
                HOSTUUIDS[$j]=$w
                HOSTNAMES[$j]=$x
            fi
            ((i++))
        done
        ((MAX--))
    done
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

setup 
while getopts :dcubnmh opt ;do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                c) CSV="yes" ;;
                u) MODE="uuid" ;;
                b) MODE="both" ;;
                n) MODE="name" ;;
                m) MODE="mixed" ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

# Set Title array depending on MODE
case "$MODE" in
	"uuid") TITLES=( 'VM UUID' 'Status' 'Host UUID' ) ;;
	"name") TITLES=( 'VM Name' 'Status' 'Host Name' ) ;;
	"mixed")  TITLES=( 'VM Name' 'Status' 'VM UUID' 'Host Name' ) ;;
	"both") TITLES=( 'VM Name' 'Status' 'VM UUID' 'Host Name' 'Host UUID' ) ;;
esac

# Populate arrays for VM UUIDs, VM name-label, power state, Host Name and Host UUID
VMUUIDS=( $(xe vm-list params=uuid is-control-domain=false --minimal | sed 's/,/\n/g') )
for i in $(seq 0 $(( ${#VMUUIDS[@]} - 1 )) ) ;do
	VMNAMES[$i]=$(xe vm-param-get uuid="${VMUUIDS[$i]}" param-name=name-label)
	STATES[$i]=$(xe vm-param-get uuid="${VMUUIDS[$i]}"  param-name=power-state)
	HOSTUUIDS[$i]=$(xe vm-param-get uuid="${VMUUIDS[$i]}" param-name=resident-on)
	if [[ "${HOSTUUIDS[$i]}" = '<not in database>' ]] ;then
		HOSTUUIDS[$i]="" ; HOSTNAMES[$i]=""
	else
		HOSTNAMES[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=name-label)
	fi
done

# Bubble sort the vm date in alphabetical order by VMNAMES[]
sort_vmnames

# Get the length of each column and store it in COLLONGEST[]
case "$MODE" in
	"uuid") COLLONGEST[0]=$(getcolwidth "${TITLES[2]}" "${VMUUIDS[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[4]}" "${HOSTUUIDS[@]}")
	 ;;
	"name") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[3]}" "${HOSTNAMES[@]}")
	 ;;
	"mixed") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${VMUUIDS[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${HOSTNAMES[@]}")
	 ;;
	 "both") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${VMUUIDS[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${HOSTNAMES[@]}")
			COLLONGEST[4]=$(getcolwidth "${TITLES[4]}" "${HOSTUUIDS[@]}")
	 ;;
esac

# Print column headings
for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
	cecho "${TITLES[$i]}" off
	printspaces "${COLLONGEST[$i]}"  "${#TITLES[$i]}" 	
done
echo ""

# Print data columns
for i in $(seq 0 $(( ${#VMUUIDS[@]} - 1 )) ) ;do
	case "$MODE" in
		"uuid") cecho "${VMUUIDS[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMUUIDS[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${HOSTUUIDS[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTUUIDS[$i]}"
		;;
		"name") cecho "${VMNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMNAMES[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${HOSTNAMES[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTNAMES[$i]}" 
		;;
		"mixed") cecho "${VMNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMNAMES[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${VMUUIDS[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#VMUUIDS[$i]}"
				cecho "${HOSTNAMES[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTNAMES[$i]}" 
		;;
		"both") cecho "${VMNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMNAMES[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${VMUUIDS[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#VMUUIDS[$i]}"
				cecho "${HOSTNAMES[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTNAMES[$i]}" 
				cecho "${HOSTUUIDS[$i]}" blue ; printspaces "${COLLONGEST[4]}" "${#HOSTUUIDS[$i]}"
		;;
	esac  
	echo ""   
done
