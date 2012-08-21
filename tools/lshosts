#!/bin/bash

# Lists the number of XCP/Xenserver Virtual Machines on each host
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 22, 2012
# Version: 0.6
# Date: August 20, 2012
# Complete rewrite

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
        echo "-h - this help text"
        echo "-u - show UUIDs"
        echo "-c - print as csv"
        echo ""
        exit
}

#get width of columns
getcolwidth()
{
	#get longest item in array
	array=( "$@" )
	i=0
	for ITEM in ${array[@]} "${TITLES[$2]}" ;do
		if [[ "${#ITEM}" -gt "${COLLONGEST[$2]}" ]] ;then
			COLLONGEST[$2]="${#ITEM}"
		fi
	done
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

#main
setcolors

while getopts :dhuc opt ;do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                c) CSV="yes" ;;
                u) UUID="yes" ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))
MINSPACE="3"

TITLES=( 'Host' 'Active VMs' 'SW' 'Ver' 'Processor' 'Cores' 'Mhz' 'Tot Mem' 'Free Mem' 'Network')
VMUUIDS=( $(xe vm-list params=uuid is-control-domain=false --minimal | sort | sed 's/,/\n/g') )
HOSTNAMES=( $(xe host-list params=name-label --minimal | sed 's/,/\n/g' | sort ) )

#get data about hosts
for i in $(seq 0 $(( ${#HOSTNAMES[@]} - 1 )) )
do
	HOSTUUID[$i]=$(xe host-list name-label=${HOSTNAMES[$i]} params=uuid --minimal)
	HOSTVMNUM[$i]=$(xe vm-list params=resident-on power-state=running  is-control-domain=false | grep -c "$HOSTUUID")
	HOSTSWTYPE[$i]=$(xe host-param-get uuid="$HOSTUUID" param-name=software-version param-key=product_brand)
	HOSTSWVER[$i]=$(xe host-param-get uuid="$HOSTUUID" param-name=software-version param-key=product_version)
	HOSTCPUTYPE[$i]=$(xe host-param-get uuid="$HOSTUUID" param-name=cpu_info param-key=vendor)
	HOSTCPUCOUNT[$i]=$(xe host-param-get uuid="$HOSTUUID" param-name=cpu_info param-key=cpu_count)
	HOSTCPUSPEED[$i]=$(xe host-param-get uuid="$HOSTUUID" param-name=cpu_info param-key=speed | awk -F. '{print $1}')
	HOSTMAXMEM[$i]=$(getunit $(xe host-param-get uuid="$HOSTUUID" param-name=memory-total))
	HOSTMAXFREE[$i]=$(getunit $(xe host-param-get uuid="$HOSTUUID" param-name=memory-free))
	HOSTNETWORK[$i]=$(xe host-param-get uuid="$HOSTUUID" param-name=software-version param-key=network_backend)
done

#set col1 as name-label or uuid
if [[ "$UUID" = "yes" ]] ;then
	HOSTCOL=("${HOSTUUID[@]}")
else
	HOSTCOL=("${HOSTNAMES[@]}")
fi

#get column widths
getcolwidth "${HOSTCOL[@]}" 0
getcolwidth "${HOSTVMNUM[@]}" 1
getcolwidth "${HOSTSWTYPE[@]}" 2
getcolwidth "${HOSTSWVER[@]}" 3
getcolwidth "${HOSTCPUTYPE[@]}" 4
getcolwidth "${HOSTCPUCOUNT[@]}" 5
getcolwidth "${HOSTCPUSPEED[@]}" 6
getcolwidth "${HOSTMAXMEM[@]}" 7
getcolwidth "${HOSTMAXFREE[@]}" 8
getcolwidth "${HOSTNETWORK[@]}" 9

#print title
IFS=$'\n'
if [[ "$CSV" = "yes" ]] ;then
	for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) )
	do
		if [[ "$i" = $(( ${#TITLES[@]} - 1 )) ]] ;then
			echo -ne "${TITLES[$i]}"
		else
			echo -ne "${TITLES[$i]},"
		fi
	done
else
	for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
		cecho "${TITLES[$i]}" off
		printf "%*s" "$(( ${COLLONGEST[$i]} + $MINSPACE - ${#TITLES[$i]} ))" 	
	done
fi
echo ""

#print host data columns
if [[ "$CSV" = "yes" ]] ;then
	for i in $(seq 0 $(( ${#HOSTCOL[@]} - 1 )) ) ;do
		echo -ne "${HOSTCOL[$i]},"
		echo -ne "${HOSTVMNUM[$i]},"
		echo -ne "${HOSTSWTYPE[$i]}," 
		echo -ne "${HOSTSWVER[$i]},"
		echo -ne "${HOSTCPUTYPE[$i]}," 
		echo -ne "${HOSTCPUCOUNT[$i]}," 
		echo -ne "${HOSTCPUSPEED[$i]}," 
		echo -ne "${HOSTMAXMEM[$i]}," 
		echo -ne "${HOSTMAXFREE[$i]}," 
		echo -ne "${HOSTNETWORK[$i]}" 
	done
else
	for i in $(seq 0 $(( ${#HOSTCOL[@]} - 1 )) ) ;do
		cecho "${HOSTCOL[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[0]} + $MINSPACE - ${#HOSTCOL[$i]} ))" 
		cecho "${HOSTVMNUM[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[1]} + $MINSPACE - ${#HOSTVMNUM[$i]} ))" 
		cecho "${HOSTSWTYPE[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[2]} + $MINSPACE - ${#HOSTSWTYPE[$i]} ))" 
		cecho "${HOSTSWVER[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[3]} + $MINSPACE - ${#HOSTSWVER[$i]} ))" 
		cecho "${HOSTCPUTYPE[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[4]} + $MINSPACE - ${#HOSTCPUTYPE[$i]} ))" 
		cecho "${HOSTCPUCOUNT[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[5]} + $MINSPACE - ${#HOSTCPUCOUNT[$i]} ))" 
		cecho "${HOSTCPUSPEED[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[6]} + $MINSPACE - ${#HOSTCPUSPEED[$i]} ))" 
		cecho "${HOSTMAXMEM[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[7]} + $MINSPACE - ${#HOSTMAXMEM[$i]} ))" 
		cecho "${HOSTMAXFREE[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[8]} + $MINSPACE - ${#HOSTMAXFREE[$i]} ))" 
		cecho "${HOSTNETWORK[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[9]} + $MINSPACE - ${#HOSTNETWORK[$i]} ))" 
	done
fi
echo ""
