#!/bin/bash

# Shows virtual disk information
# Authors: Lisa Nguyen (ltn821@hotmail.com), Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: 9/10/2012 

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
	MSG=${1}       
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
	echo "-c - print as csv"
        echo ""
        exit
}

getunit()
{
 	SIZE="$1"
        for UNIT in K M G
        do
                SIZE=$(echo "scale=0; $SIZE / 1024" | bc)
                if [[ $SIZE -lt 1024 ]]
                then
                        SIZE=${SIZE}${UNIT}
                        break
                fi
        done
	echo "$SIZE"
}

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

IFS=$'\n'
NAMELONGEST=0
setcolors

while getopts :dhc opt
do
        case $opt in
                d) set -x ;;
                h) syntax ;;
		c) CSV="yes" ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

#number of spaces for formatting
SPACE="3"

#get list of Titles, VDI uuids, SR names, VMs, and device names
TITLES=( 'VDI' 'Size' 'SR Name' 'SR Type' 'VM' 'Device' )
VDIUUIDS=( $(xe vdi-list params=uuid --minimal | sed 's/\,/\n/g' | sed '/^$/d') )

for i in $(seq 0 $(( ${#VDIUUIDS[@]} - 1 ))) ;do
	SRNAMES[$i]=$(xe vdi-param-get uuid=${VDIUUIDS[$i]} param-name=sr-name-label | tr -d \”)
	SRUUID=$(xe vdi-param-get uuid=${VDIUUIDS[$i]} param-name=sr-uuid)
	SRTYPES[$i]=$(xe sr-list uuid=$SRUUID params=type --minimal)
	VBDUUID=$(xe vbd-list vdi-uuid=${VDIUUIDS[$i]} --minimal)
	VDISIZE=$(xe vdi-param-get uuid=${VDIUUIDS[$i]} param-name=virtual-size)

        #checking valid VDI size
        if [[ $VDISIZE = '-1' ]] ; then
        	VDISIZE=0
        fi
	
	TOTALSIZE[$i]=$(getunit $VDISIZE)	

	#if VBD uuid exists
	if [ ! -z "$VBDUUID" ] ;then
		VMUUID=$(xe vbd-param-get uuid=$VBDUUID param-name=vm-uuid)
		VMNAME[$i]=$(xe vm-param-get uuid=$VMUUID param-name=name-label)
		DEVICENAME[$i]=$(xe vbd-param-get uuid=$VBDUUID param-name=device)
	else
		VMNAME[$i]=""
		DEVICENAME[$i]=""
	fi
done

#calculate column width
COLLONGEST[0]=$(getcolwidth  "${TITLES[0]}" "${VDIUUIDS[@]}")
COLLONGEST[1]="4" # width of size will never be longer than 4 ie. 999M then 1G
COLLONGEST[2]=$(getcolwidth  "${TITLES[2]}" "${SRNAMES[@]}")
COLLONGEST[3]=$(getcolwidth  "${TITLES[3]}" "${SRTYPES[@]}")
COLLONGEST[4]=$(getcolwidth  "${TITLES[4]}" "${VMNAMES[@]}" "No VM Attached")
COLLONGEST[5]=$(getcolwidth  "${TITLES[5]}" "${VBDNAMES[@]}" "No Device")

#prints titles
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
	echo ""
else
	for i in $(seq 0 $(( ${#TITLES[@]} - 1 )))
	do
		cecho "${TITLES[$i]}" off ; printf "%*s" "$(( ${COLLONGEST[$i]} + $SPACE - ${#TITLES[$i]} ))" 
	done
echo ""
fi

#output VDI information
if [[ "$CSV" = "yes" ]] ;then
	 for i in $(seq 0 $(( ${#VDIUUIDS[@]} - 1 )) ) ;do
         	echo -ne "${VDIUUIDS[$i]},"
	 	echo -ne "${TOTALSIZE[$i]},"
		echo -ne "${SRNAMES[$i]},"
		echo -ne "${SRTYPES[$i]},"
		echo -ne "${VMNAME[$i]},"
		echo -ne "${DEVICENAME[$i]}"
		echo ""
        done
else
	for i in $(seq 0 $(( ${#VDIUUIDS[@]} - 1 ))) 
	do
		#print rows
		cecho "${VDIUUIDS[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[0]} + $SPACE - ${#VDIUUIDS[$i]} ))" 
		cecho "${TOTALSIZE[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[1]} + $SPACE - ${#TOTALSIZE[$i]} ))" 
		cecho "${SRNAMES[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[2]} + $SPACE - ${#SRNAMES[$i]} ))" 
		cecho "${SRTYPES[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[3]} + $SPACE - ${#SRTYPES[$i]} ))"
		cecho "${VMNAME[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[4]} + $SPACE - ${#VMNAME[$i]} ))"
		cecho "${DEVICENAME[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[5]} + $SPACE - ${#DEVICENAME[$i]} ))"
		echo ""
	done
fi
