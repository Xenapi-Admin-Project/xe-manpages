#!/bin/bash

# Deletes XCP/Xenserver template
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: August 22, 2012
# Version: 0.6
# Date: Sept 28, 2012
# Moved setcolors, cecho, getcolwidth and printspaces to library.sh

. ./library.sh

setup()
{
	TMPDIR=$(mktemp -d)
	MINSPACE="3"
	setcolors
	PROGNAME=$(basename $0)
	IFS=$'\n'
}

syntax()
{
		echo "$PROGNAME $VERSION"
        echo ""
        echo "Syntax: $PROGNAME [options]"
        echo "Options:"
        echo "-d - shell debugging"
        echo "-h - this help text"
        echo ""
        exit 1
}

cleanup()
{
	rm -Rf "$TMPDIR"
	echo "Exiting"
	exit
}

remove_template()
{
	TEMPLATE="$1"
	xe template-param-set other-config:default_template=false uuid="$TEMPLATE"
	xe template-param-set is-a-template=false uuid="$TEMPLATE"
	xe vm-destroy uuid="$TEMPLATE"
}

#main
setup

while getopts :dh opt ;do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))


TMPLNAMES=( $(xe template-list params=name-label --minimal | sed 's/,/\n/g' ) )
TMPLUUIDS=( $(xe template-list params=uuid --minimal | sort | sed 's/,/\n/g') )
HOSTNAMES=( $(xe template-list params=name-label --minimal | sed 's/,/\n/g' | sort ) )
getcolwidth "0" "${HOSTNAMES[@]}" 
getcolwidth "1" "${TMPLUUIDS[@]}" 

for i in $(seq 0 $(( ${#TMPLNAMES[@]} - 1 )) ) ;do
	cecho "${TMPLNAMES[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[0]} + $MINSPACE - ${#TMPLNAMES[$i]} ))"
	echo "$(( ${COLLONGEST[0]} + $MINSPACE - ${#TMPLNAMES[$i]} ))"
	#cecho "${TMPLUUIDS[$i]}" cyan ; printf "%*s" "$(( ${COLLONGEST[1]} + $MINSPACE - ${#TMPLUUIDS[$i]} ))" 
	echo ""
done

exit

TEMPLATE="$1"
if [[ -z "$TEMPLATE" ]]
then
	UUIDLIST=$(xe template-list params=uuid --minimal | sed 's/,/\n/g' | sed '/^$/d')
	for TMPLUUID in $UUIDLIST
	do
		TMPLNAME=$(xe template-list uuid="$TMPLUUID" params=name-label --minimal)
		echo "$TMPLNAME $TMPLUUID" >> "$TMPDIR/templatelist.txt"
	done
	sort "$TMPDIR/templatelist.txt" > "$TMPDIR/sortedtemplatelist.txt"
	cat "$TMPDIR/sortedtemplatelist.txt"
	exit
	
	PS3="Please select template to removed: "
	select ITEM in $(cat "$TMPDIR/sortedtemplatelist.txt") "Quit"
	do
		case "$ITEM" in
			"$Quit")
				cleanup
			;;
			*)
				echo "Removing $ITEM"
				TMPLCOUNT=$(xe template-list name-label=test-template params=name-label | sed '/^$/d' | grep -c test-template)
				if [[ "$TMPLCOUNT" -gt "1" ]] ;then
					:
				else
					TMPLUUID=$(xe template-list name-label="$ITEM" --minimal)
					echo remove_template "$TMPLUUID"
				fi
				break
			;;
		esac
	done
else
	:
fi



