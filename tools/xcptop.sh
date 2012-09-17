#!/bin/bash

# Lists the load on each Host CPU core
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 22, 2012
# Version: 0.6
# Date: September 16, 2012
# Complete rewrite to use getcolwidth and printspaces.
# Now outputs uuid/name views and CSV format

setup()
{
	setcolors
	IFS=$'\n'	
	MINSPACE="5"
	MODE="name"
	IFS=$'\n'
	REFRESH="2" #seconds
	PLACEHOLDER="--"
	VERSION="0.6"
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
	echo "-f - continuous updates"
	echo "-n - show Names (default)"
	echo "-u - show UUIDs"
	echo "-t <seconds> - continuous updates every <seconds>"
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

showcpuinfo()
{
	#Loop through hosts
	# for each host loop through CPUs, get number and load.
	
	for i in $(seq 0 $(( ${#HOSTUUIDS[@]} - 1 )) ) ;do
		case "$MODE" in
			"uuid") cecho "${HOSTUUIDS[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#HOSTUUIDS[$i]}" ;;
			"name") cecho "${HOSTNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#HOSTNAMES[$i]}" ;;
		esac
		cecho "${PLACEHOLDER}" blue ; printspaces "${COLLONGEST[1]}" "${#PLACEHOLDER}"
		cecho "${PLACEHOLDER}" blue ; printspaces "${COLLONGEST[2]}" "${#PLACEHOLDER}"
		
		COLSPACES=$(( ${COLLONGEST[0]} + $MINSPACE ))
		for CPUNUM in $(xe host-cpu-list host-uuid=${HOSTUUIDS[$i]} params=number --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort); do	
			COREUUID=$(xe host-cpu-list host-uuid="${HOSTUUIDS[$i]}" number="$CPUNUM" params=uuid --minimal)
			LOAD=$(xe host-cpu-param-get uuid="$COREUUID" param-name=utilisation)
			if [[ "$CSV" = "yes" ]] ;then
				echo "" ; echo -ne ","
			else
				echo "" ; printf "%*s" "$COLSPACES"
			fi
			case "$MODE" in
				"uuid") cecho "${COREUUID[$i]}" blue ; printspaces "${COLLONGEST[1]}" "${#COREUUID[$i]}"  ;;
				"name") cecho "${CPUNUM[$i]}" blue ; printspaces "${COLLONGEST[1]}" "${#CPUNUM[$i]}"  ;;
			esac
			cecho "${LOAD}" blue ; printspaces "${COLLONGEST[2]}" "${#LOAD}"
		done
	done
	echo ""
}

setup
while getopts :ofdt:unch opt ;do
        case $opt in
			f) FOLLOW="yes" ;;
			d) set -x ;;
			t) FOLLOW="yes"
			   REFRESH="$OPTARG" ;;		
			u) MODE="uuid" ;;
			n) MODE="name" ;; 
			c) CSV="yes" ;; 
			h) syntax ;;
            \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))


# Get Host UUIDs and related HOST Names
HOSTUUIDS=( $(xe host-list params=uuid --minimal | sed 's/,/\n/g') )
for i in $(seq 0 $(( ${#HOSTUUIDS[@]} - 1 )) ) ;do
	HOSTNAMES[$i]=$(xe host-list uuid="${HOSTUUIDS[$i]}" params=name-label --minimal)
	for ITEM in $(xe host-cpu-list host-uuid=${HOSTUUIDS[$i]} params=number --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort); do
		CPUNUMS[$i]="$ITEM"
		CPUUUIDS[$i]=$(xe host-cpu-list host-uuid="${HOSTUUIDS[$i]}" number="$CPUNUMS" params=uuid --minimal)
		CPULOADS[$i]=$(xe host-cpu-param-get uuid="$CPUUUIDS" param-name=utilisation)
	done
done

# Set TITLE array and Column width depending on MODE
case "$MODE" in
	"uuid") TITLES=( 'Host UUID' 'CPU Core' 'Utilization' ) 
			COLLONGEST[0]=$(getcolwidth "${TITLES[1]}" "${HOSTUUIDS[@]}") 
			COLLONGEST[1]=$(getcolwidth "${TITLES[2]}" "${CPUUUIDS[@]}") ;;
	"name") TITLES=( 'Host' 'CPU Core' 'Utilization' ) 
			COLLONGEST[0]=$(getcolwidth "${TITLES[1]}" "${HOSTNAMES[@]}") 
			COLLONGEST[1]=$(getcolwidth "${TITLES[2]}" "${CPUNUMS[@]}") ;;
esac
COLLONGEST[2]=$(getcolwidth "${TITLES[3]}" "${CPULOAD[@]}")

# 
if [ "$FOLLOW" = "yes" ] ;then
	while true ;do
		clear
		# Print column headings
		if [ "$FOLLOW" = "yes" ] ;then
			cecho "Every ${REFRESH}s:" off ; cecho " $(basename $0)" off
			echo "" ; echo ""
		fi
		for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
			cecho "${TITLES[$i]}" off
			printspaces "${COLLONGEST[$i]}" "${#TITLES[$i]}" 	
		done
		echo ""
		showcpuinfo
		sleep "$REFRESH"
	done
else
	for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
		cecho "${TITLES[$i]}" off
		printspaces "${COLLONGEST[$i]}" "${#TITLES[$i]}" 	
	done
	echo ""
	showcpuinfo
fi

