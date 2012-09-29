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
# Version 0.7
# Date: Sept 28, 2012
# Added Domain ID in output
# Moved setcolors, cecho, getcolwidth and printspaces to library.sh
# Created printheadings

. ./library.sh

setup()
{
	setcolors
	IFS=$'\n'	
	MINSPACE="5"
	MODE="mixed"
	VERSION="0.7"
	PROGNAME=$(basename $0)
}

syntax()
{
		echo "$PROGNAME $VERSION"
        echo ""
        echo "Syntax: $PROGNAME [options]"
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
                local y=${DOMID[$i]}
                VMNAMES[$i]=${VMNAMES[$j]}
                VMUUIDS[$i]=${VMUUIDS[$j]}
                STATES[$i]=${STATES[$j]}
                HOSTUUIDS[$i]=${HOSTUUIDS[$j]}
                HOSTNAMES[$i]=${HOSTNAMES[$j]}
                DOMID[$i]=${DOMID[$j]}
                VMNAMES[$j]=$t
                VMUUIDS[$j]=$u
                STATES[$j]=$v
                HOSTUUIDS[$j]=$w
                HOSTNAMES[$j]=$x
                DOMID[$j]=$y
            fi
            ((i++))
        done
        ((MAX--))
    done
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
	"uuid") TITLES=( 'VM UUID' 'Status' 'Host UUID' 'Dom ID' ) ;;
	"name") TITLES=( 'VM Name' 'Status' 'Host Name' 'Dom ID' ) ;;
	"mixed")  TITLES=( 'VM Name' 'Status' 'VM UUID' 'Host Name' 'Dom ID' ) ;;
	"both") TITLES=( 'VM Name' 'Status' 'VM UUID' 'Host Name' 'Host UUID' 'Dom ID' ) ;;
esac

# Populate arrays for VM UUIDs, VM name-label, power state, Host Name and Host UUID
VMUUIDS=( $(xe vm-list params=uuid is-control-domain=false --minimal | sed 's/,/\n/g') )
for i in $(seq 0 $(( ${#VMUUIDS[@]} - 1 )) ) ;do
	VMNAMES[$i]=$(xe vm-param-get uuid="${VMUUIDS[$i]}" param-name=name-label)
	DOMID[$i]=$(xe vm-param-get uuid="${VMUUIDS[$i]}" param-name=dom-id)
	if [[ ${DOMID[$i]} = '-1' ]] ;then
		DOMID[$i]="--"
	fi
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
	"uuid") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMUUIDS[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${HOSTUUIDS[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${DOMID[@]}")
	 ;;
	"name") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${HOSTNAMES[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${DOMID[@]}")
	 ;;
	"mixed") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${VMUUIDS[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${HOSTNAMES[@]}")
			COLLONGEST[4]=$(getcolwidth "${TITLES[4]}" "${DOMID[@]}")
	 ;;
	 "both") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${VMNAMES[@]}")
			COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${STATES[@]}")
			COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${VMUUIDS[@]}")
			COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${HOSTNAMES[@]}")
			COLLONGEST[4]=$(getcolwidth "${TITLES[4]}" "${HOSTUUIDS[@]}")
			COLLONGEST[5]=$(getcolwidth "${TITLES[5]}" "${DOMID[@]}")
	 ;;
esac
printheadings

# Print data columns
for i in $(seq 0 $(( ${#VMUUIDS[@]} - 1 )) ) ;do
	case "$MODE" in
		"uuid") cecho "${VMUUIDS[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMUUIDS[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${HOSTUUIDS[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#HOSTUUIDS[$i]}"
				cecho "${DOMID[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#DOMID[$i]}"
		;;
		"name") cecho "${VMNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMNAMES[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${HOSTNAMES[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#HOSTNAMES[$i]}" 
				cecho "${DOMID[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#DOMID[$i]}"
		;;
		"mixed") cecho "${VMNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMNAMES[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${VMUUIDS[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#VMUUIDS[$i]}"
				cecho "${HOSTNAMES[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTNAMES[$i]}"
				cecho "${DOMID[$i]}" blue ; printspaces "${COLLONGEST[4]}" "${#DOMID[$i]}" 
		;;
		"both") cecho "${VMNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#VMNAMES[$i]}" 
				cecho "${STATES[$i]}" red ; printspaces "${COLLONGEST[1]}" "${#STATES[$i]}" 
				cecho "${VMUUIDS[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#VMUUIDS[$i]}"
				cecho "${HOSTNAMES[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTNAMES[$i]}" 
				cecho "${HOSTUUIDS[$i]}" blue ; printspaces "${COLLONGEST[4]}" "${#HOSTUUIDS[$i]}"
				cecho "${DOMID[$i]}" blue ; printspaces "${COLLONGEST[5]}" "${#DOMID[$i]}"
		;;
	esac  
	echo ""   
done
