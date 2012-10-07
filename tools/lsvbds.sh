#!/bin/bash

# Shows virtual block device information
# Authors: Lisa Nguyen (ltn821@hotmail.com), Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: 10/6/2012  

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
SPACE="2"

#get list 
TITLES=( 'VBD' 'VDI' 'VM' 'Device' 'Attached' )
VBDUUIDS=( $(xe vbd-list params=uuid --minimal | sed 's/\,/\n/g' | sed '/^$/d') )

for i in $(seq 0 $(( ${#VBDUUIDS[@]} - 1 ))) ;do
	VDIUUIDS[$i]=$(xe vbd-param-get uuid=${VBDUUIDS[$i]} param-name=vdi-uuid)
	VMNAMES[$i]=$(xe vbd-param-get uuid=${VBDUUIDS[$i]} param-name=vm-name-label)
	DEVICES[$i]=$(xe vbd-param-get uuid=${VBDUUIDS[$i]} param-name=device)
	ATTACHED[$i]=$(xe vbd-param-get uuid=${VBDUUIDS[$i]} param-name=currently-attached)
done

#calculate column width
COLLONGEST[0]=$(getcolwidth  "${TITLES[0]}" "${VBDUUIDS[@]}")
COLLONGEST[1]=$(getcolwidth  "${TITLES[1]}" "${VDIUUIDS[@]}")
COLLONGEST[2]=$(getcolwidth  "${TITLES[2]}" "${VMNAMES[@]}")
COLLONGEST[3]=$(getcolwidth  "${TITLES[3]}" "${DEVICES[@]}")
COLLONGEST[4]=$(getcolwidth  "${TITLES[4]}" "${ATTACHED[@]}")

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
	 for i in $(seq 0 $(( ${#VBDUUIDS[@]} - 1 )) ) ;do
		echo -ne "${VBDUUIDS[$i]},"
         	echo -ne "${VDIUUIDS[$i]},"
		echo -ne "${VMNAMES[$i]},"
		echo -ne "${DEVICES[$i]},"
		echo -ne "${ATTACHED[$i]}"
		echo ""
        done
else
	for i in $(seq 0 $(( ${#VBDUUIDS[@]} - 1 ))) 
	do
		#print rows
		cecho "${VBDUUIDS[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[0]} + $SPACE - ${#VBDUUIDS[$i]} ))" 
		cecho "${VDIUUIDS[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[1]} + $SPACE - ${#VDIUUIDS[$i]} ))"
		cecho "${VMNAMES[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[2]} + $SPACE - ${#VMNAMES[$i]} ))"
		cecho "${DEVICES[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[3]} + $SPACE - ${#DEVICES[$i]} ))"
		cecho "${ATTACHED[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[4]} + $SPACE - ${#ATTACHED[$i]} ))"
		echo ""
	done
fi
