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
# Version 0.9
# Date Sept 14, 2012
# Added printspaces function and CSV support
# Version 0.10
# Date Sept 28, 2012
# Moved setcolors, cecho, getcolwidth and printspaces to library.sh

. ./library.sh

setup()
{
	setcolors
	TMPDIR=$(mktemp -d)
	IFS=$'\n'
	MINSPACE="3"
	TITLES=( 'Template' 'UUID' )
	declare -a TMPLNAMES
}

syntax()
{
	echo ""
	echo "Syntax: $(basename $0) [options]"
	echo "Options:"
	echo "-d - shell debugging"
	echo "-h - this help text"
    echo "-c - output comma seperated values"
	echo "-v - verbose mode, show template descriptions"
	echo ""
	exit
}

cleanup()
{
	rm -Rf "$TMPDIR"
}

trap cleanup SIGINT SIGTERM
setup

while getopts :dvch opt
do
        case $opt in
                d) set -x ;;
                v) MODE="verbose" ;;
                c) CSV="yes" ;;
				h) syntax ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))

# Populate arrays for Template UUIDs and Template Nmes
TMPLUUIDS=( $(xe template-list params=uuid --minimal | sed 's/,/\n/g') )
for i in $(seq 0 $(( ${#TMPLUUIDS[@]} - 1 )) ) ;do
	TMPLNAMES[$i]=$(xe template-list uuid="${TMPLUUIDS[$i]}" params=name-label --minimal)
done

# Get the length of each column and store it in COLLONGEST[]
COLLONGEST[0]=$(getcolwidth "${TITLES[0]}" "${TMPLNAMES[@]}")
COLLONGEST[1]=$(getcolwidth "${TITLES[1]}" "${TMPLUUIDS[@]}")

# Print column headings
for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
	cecho "${TITLES[$i]}" off ; printspaces "${COLLONGEST[$i]}" "${#TITLES[$i]}" 
done > "$TMPDIR/tmpllist.txt"
echo "" >> "$TMPDIR/tmpllist.txt"

# sort template names and UUIDs using the sort command (twice as fast as bash or eval)
for i in $(seq 0 $(( ${#TMPLUUIDS[@]} - 1 )) ) ;do
	cecho "${TMPLNAMES[$i]}" cyan ;	printspaces "${COLLONGEST[0]}" "${#TMPLNAMES[$i]}" 
	cecho "${TMPLUUIDS[$i]}" blue ;	printspaces "${COLLONGEST[1]}" "${#TMPLUUIDS[$i]}" 
	echo "" 
done | sort >> "$TMPDIR/tmpllist.txt"

# Print data columns
if [[ "$MODE" = "verbose" ]] ;then
	for LINE in $(cat $TMPDIR/tmpllist.txt) ;do
		echo "$LINE"
		UUID=$(echo "$LINE" | egrep -o '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
		xe template-param-get uuid="$UUID" params-name=name-description
		echo ""
	done
else
	for LINE in $(cat $TMPDIR/tmpllist.txt) ;do
		echo "$LINE"
	done
fi

cleanup
