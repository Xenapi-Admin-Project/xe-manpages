#!/bin/bash

# Shows storage repository size
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 25, 2012
# Version: 0.6
# Date: Sept 14, 2012
# Rewrote using getcolwidth, printspaces and sort_srnames
# Version: 0.7
# Date: Sept 15, 2012
# Moved to MODE= to allow for future expansion

setup()
{
	IFS=$'\n'
	setcolors
	MINSPACE="10"
	VERSION="0.7"
	MODE="name"
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
	MSG=${1}       
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
        echo "-h - this help text"
        echo "-c - output comma seperated values"
        echo "-u - show UUIDs"
        echo "-n - show Names (default)"
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

sort_srnames()
{   
	local MAX=$((${#SRNAMES[@]} - 1))
    while ((MAX > 0)) ;do
       	local i=0 
        while ((i < MAX)) ;do
			local j=$((i + 1))
			if expr "${SRNAMES[$i]}" \> "${SRNAMES[$j]}" >/dev/null
			then
                local t=${SRNAMES[$i]}
                local u=${SRUUIDS[$i]}
                local v=${SRTYPE[$i]}
                SRNAMES[$i]=${SRNAMES[$j]}
                SRUUIDS[$i]=${SRUUIDS[$j]}
                SRTYPE[$i]=${SRTYPE[$j]}
                SRNAMES[$j]=$t
                SRUUIDS[$j]=$u
                SRTYPE[$j]=$v
            fi
            ((i++))
        done
        ((MAX--))
    done
}

printspaces()
{
	# arg 1 - the longest item in the column
	# arg 2 - the length of the item ie. ${#VAR}
	COLUMN="$1"
	ITEM="$2"
	
	if [[ "$CSV" = "yes" ]] ;then
		echo -ne ","
	else
		printf "%*s" "$(( $COLUMN + $MINSPACE - $ITEM ))"
	fi 
}

setup
while getopts :dhunc opt
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

# Set Title array depending on MODE
case "$MODE" in
	"uuid") TITLES=( 'Storage Repository UUID' 'Size' 'Used' 'Avail' 'Full' 'SR Type') ;;
	"name") TITLES=( 'Storage Repository' 'Size' 'Used' 'Avail' 'Full' 'SR Type') ;;
esac


SRUUIDS=( $(xe sr-list params=uuid --minimal | sed 's/,/\n/g') ) 
for i in $(seq 0 $(( ${#SRUUIDS[@]} - 1 )) ) ;do
	SRNAMES[$i]=$(xe sr-list uuid="${SRUUIDS[$i]}" params=name-label --minimal | sed 's/,/\n/g' | tr -d \”)
	SRTYPE[$i]=$(xe sr-param-get uuid="${SRUUIDS[$i]}" param-name=type)
done
sort_srnames

# Get COLLONGEST depending on MODE
case "$MODE" in
	"uuid") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${SRUUIDS[@]}") ;;
	"name") COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${SRNAMES[@]}") ;;
esac
COLLONGEST[1]="4"
COLLONGEST[2]="4"
COLLONGEST[3]="4"
COLLONGEST[4]="4"
COLLONGEST[5]=$(getcolwidth "${TITLES[5]}" "${SRTYPE[@]}")

# Print column headings
for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
	cecho "${TITLES[$i]}" off ; printspaces "${COLLONGEST[$i]}" "${#TITLES[$i]}"
done
echo ""

i=0
for i in $(seq 0 $(( ${#SRUUIDS[@]} - 1 )) ) ;do
	SRUSED=$(xe sr-param-get uuid=${SRUUIDS[$i]} param-name=physical-utilisation)
	SRSIZE=$(xe sr-param-get uuid=${SRUUIDS[$i]} param-name=physical-size)
	if [[ $SRUSED = '-1' || $SRSIZE = '-1' ]] ; then
		SRUSED=0 ; SRSIZE=0
	fi
	if [[ "$SRSIZE" -gt 0 ]] ;then
		PERCENTSIZE=$(echo "scale=2; $SRUSED / $SRSIZE * 100" | bc | sed s/\\.[0-9]\\+//)
	else
		PERCENTSIZE="100"	
	fi
	
	TOTALSIZE=$(getunit "$SRSIZE")
	USEDSIZE=$(getunit "$SRUSED")
	TEMPSIZE=$(( $SRSIZE - $SRUSED ))
	FREESIZE=$(getunit "$TEMPSIZE")
    case "$MODE" in
		"uuid") cecho "${SRUUIDS[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#SRUUIDS[$i]}"  ;;
		"name") cecho "${SRNAMES[$i]}" cyan ; printspaces "${COLLONGEST[0]}" "${#SRNAMES[$i]}"  ;;
	esac    
    cecho "${TOTALSIZE}" blue ; printspaces "${COLLONGEST[1]}" "${#TOTALSIZE}" 
    cecho "${USEDSIZE}" blue ; printspaces "${COLLONGEST[2]}" "${#USEDSIZE}" 
    cecho "${FREESIZE}" blue ; printspaces "${COLLONGEST[3]}" "${#FREESIZE}" 
    cecho "${PERCENTSIZE}" blue ; printspaces "${COLLONGEST[4]}" "${#PERCENTSIZE}" 
    cecho "${SRTYPE[$i]}" blue ; printspaces "${COLLONGEST[5]}" "${#SRTYPE[$i]}" 
	echo ""
done

