#!/bin/bash
# Lists XCP/Xenserver templates
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.6
# Date: June 27, 2012
# Version: 0.7
# Date: Sept 3, 2012
# UUIDs didn't match up to sorted name-labels
# Much slower now with internal bubble sort but it's correct
# Version 0.8
# Date: Sept 12, 2012
# Replaced bubble sort with an outside file sorted using the sort command
# execution time went from 4.2 seconds to 1.8.
# changed getcolwidth to a function returning the longest length instead of setting COLLONGEST directly

setup()
{
	setcolors
	TMPDIR=$(mktemp -d)
	IFS=$'\n'
	MINSPACE="3"
	TITLES=( 'Template' 'UUID' )
	declare -a TMPLNAMES
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
	echo "-h - this help text"
	echo "-v - verbose mode, show template descriptions"
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

cleanup()
{
	rm -Rf "$TMPDIR"
}

trap cleanup SIGINT SIGTERM
setup

while getopts :dvh opt
do
        case $opt in
                d) set -x ;;
                v) MODE="verbose" ;;
				h) syntax ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

i=0
TMPLUUIDS=( $(xe template-list params=uuid --minimal | sed 's/,/\n/g') )
for i in $(seq 0 $(( ${#TMPLUUIDS[@]} - 1 )) ) ;do
	TMPLNAMES[$i]=$(xe template-list uuid="${TMPLUUIDS[$i]}" params=name-label --minimal)
	
done

COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${TMPLNAMES[@]}")
COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${TMPLUUIDS[@]}")

for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
	cecho "${TITLES[$i]}" off ; printf "%*s" "$(( ${COLLONGEST[0]} + $MINSPACE - ${#TITLES[$i]} ))" 
done > "$TMPDIR/tmpllist.txt"
echo "" >> "$TMPDIR/tmpllist.txt"

for i in $(seq 0 $(( ${#TMPLUUIDS[@]} - 1 )) ) ;do
	cecho "${TMPLNAMES[$i]}" cyan ;	printf "%*s" "$(( ${COLLONGEST[0]} + $MINSPACE - ${#TMPLNAMES[$i]} ))" 
	cecho "${TMPLUUIDS[$i]}" cyan ;	printf "%*s" "$(( ${COLLONGEST[1]} + $MINSPACE - ${#TMPLUUIDS[$i]} ))" 
	echo "" 
done | sort >> "$TMPDIR/tmpllist.txt"

if [[ "$MODE" = "verbose" ]] ;then
	for LINE in $(cat $TMPDIR/tmpllist.txt) ;do
		echo "$LINE"
		UUID=$(echo "$LINE" | egrep -o '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
		xe template-list uuid="$UUID" params=name-description --minimal
		echo ""
	done
else
	for LINE in $(cat $TMPDIR/tmpllist.txt) ;do
		echo "$LINE"
	done
fi

cleanup
