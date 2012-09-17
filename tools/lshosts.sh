#!/bin/bash

# Lists the number of XCP/Xenserver Virtual Machines on each host
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 22, 2012
# Version: 0.6
# Date: August 20, 2012
# Complete rewrite
# Version 0.7
# Date: Sept 12, 2012
# Changed to the new style getcolwidth and printspaces
# Version 0.8
# Date: Sept 15, 2012
# Changed to MODE structure to allow for future expansion

setup()
{
	setcolors
	VERSION="0.8"
	MINSPACE="3"
	MODE="name"
	IFS=$'\n'
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
		echo "$(basename $0) $VERSION"
        echo ""
        echo "Syntax: $(basename $0) [options]"
        echo "Options:"
        echo "-d - shell debugging"
        echo "-h - this help text"
        echo "-u - show UUIDs"
        echo "-n - show Names (default)"
        echo "-c - output comma seperated values"
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

#change bytes to human readable
getunit()
{
 	SIZE="$1"
        for UNIT in K M G ;do
                SIZE=$(echo "scale=0; $SIZE / 1024" | bc)
                if [[ $SIZE -lt 1024 ]] ;then
                        SIZE=${SIZE}${UNIT}
                        break
                fi
        done
	echo "$SIZE"
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

#main
setup

while getopts :dhunc opt ;do
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

# Set Title array depending on MODE
case "$MODE" in
	"uuid") TITLES=( 'Host UUID' 'Active VMs' 'SW' 'Ver' 'Processor' 'Cores' 'Mhz' 'Tot Mem' 'Free Mem' 'Network') ;;
	"name") TITLES=( 'Host' 'Active VMs' 'SW' 'Ver' 'Processor' 'Cores' 'Mhz' 'Tot Mem' 'Free Mem' 'Network') ;;
esac

# Populate arrays for VM UUIDs and Host names
VMUUIDS=( $(xe vm-list params=uuid is-control-domain=false --minimal | sort | sed 's/,/\n/g') )
HOSTNAMES=( $(xe host-list params=name-label --minimal | sed 's/,/\n/g' | sort ) )

# Get data about hosts
HOSTUUIDS=( $(xe host-list params=uuid --minimal | sed 's/,/\n/g') )
for i in $(seq 0 $(( ${#HOSTUUIDS[@]} - 1 )) ) ;do
	HOSTNAMES[$i]=$(xe host-list uuid="${HOSTUUIDS[$i]}" params=name-label --minimal)
	HOSTVMNUM[$i]=$(xe vm-list params=resident-on power-state=running  is-control-domain=false | grep -c "${HOSTUUIDS[$i]}")
	HOSTSWTYPE[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=software-version param-key=product_brand)
	HOSTSWVER[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=software-version param-key=product_version)
	HOSTCPUTYPE[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=cpu_info param-key=vendor)
	HOSTCPUCOUNT[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=cpu_info param-key=cpu_count)
	HOSTCPUSPEED[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=cpu_info param-key=speed | awk -F. '{print $1}')
	HOSTMAXMEM[$i]=$(getunit $(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=memory-total))
	HOSTMAXFREE[$i]=$(getunit $(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=memory-free))
	HOSTNETWORK[$i]=$(xe host-param-get uuid="${HOSTUUIDS[$i]}" param-name=software-version param-key=network_backend)
done

# Get the length of each column and store it in COLLONGEST[]
case "$MODE" in
	"uuid") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${HOSTUUIDS[@]}") ;;
	"name") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${HOSTNAMES[@]}");;
esac
COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${HOSTVMNUM[@]}")
COLLONGEST[2]=$(getcolwidth "${TITLES[2]}" "${HOSTSWTYPE[@]}")
COLLONGEST[3]=$(getcolwidth "${TITLES[3]}" "${HOSTSWVER[@]}")
COLLONGEST[4]=$(getcolwidth "${TITLES[4]}" "${HOSTCPUTYPE[@]}")
COLLONGEST[5]=$(getcolwidth "${TITLES[5]}" "${HOSTCPUCOUNT[@]}")
COLLONGEST[6]=$(getcolwidth "${TITLES[6]}" "${HOSTCPUSPEED[@]}")
COLLONGEST[7]=$(getcolwidth "${TITLES[7]}" "${HOSTMAXMEM[@]}")
COLLONGEST[8]=$(getcolwidth "${TITLES[8]}" "${HOSTMAXFREE[@]}")
COLLONGEST[9]=$(getcolwidth "${TITLES[9]}" "${HOSTNETWORK[@]}")

# Print column headings
for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
	cecho "${TITLES[$i]}" off
	printspaces "${COLLONGEST[$i]}"  "${#TITLES[$i]}" 	
done
echo ""

# Print data columns
for i in $(seq 0 $(( ${#HOSTUUIDS[@]} - 1 )) ) ;do
	case "$MODE" in
		"uuid") cecho "${HOSTUUIDS[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#HOSTUUIDS[$i]}"  ;;
		"name") cecho "${HOSTNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#HOSTNAMES[$i]}"  ;;
	esac
	cecho "${HOSTVMNUM[$i]}" blue ; printspaces "${COLLONGEST[1]}" "${#HOSTVMNUM[$i]}" 
	cecho "${HOSTSWTYPE[$i]}" blue ; printspaces "${COLLONGEST[2]}" "${#HOSTSWTYPE[$i]}" 
	cecho "${HOSTSWVER[$i]}" blue ; printspaces "${COLLONGEST[3]}" "${#HOSTSWVER[$i]}" 
	cecho "${HOSTCPUTYPE[$i]}" blue ; printspaces "${COLLONGEST[4]}" "${#HOSTCPUTYPE[$i]}" 
	cecho "${HOSTCPUCOUNT[$i]}" blue ; printspaces "${COLLONGEST[5]}" "${#HOSTCPUCOUNT[$i]}" 
	cecho "${HOSTCPUSPEED[$i]}" blue ; printspaces "${COLLONGEST[6]}" "${#HOSTCPUSPEED[$i]}" 
	cecho "${HOSTMAXMEM[$i]}" blue ; printspaces "${COLLONGEST[7]}" "${#HOSTMAXMEM[$i]}" 
	cecho "${HOSTMAXFREE[$i]}" blue ; printspaces "${COLLONGEST[8]}" "${#HOSTMAXFREE[$i]}" 
	cecho "${HOSTNETWORK[$i]}" blue ; printspaces "${COLLONGEST[9]}" "${#HOSTNETWORK[$i]}" 
done
echo ""
