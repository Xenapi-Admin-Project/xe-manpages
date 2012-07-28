#!/bin/bash
# Lists XCP/Xenserver templates
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: June 27, 2012

setcolors()
{
	red='\e[0;31m'
	blue='\e[0;34m'
	cyan='\e[0;36m'
	off='\e[0m'
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

setcolors
LIST=$(xe template-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)

IFS=$'\n'
LONGEST=0

for TEMPLATE in $LIST
do
  	if [[ ${#TEMPLATE} -gt $LONGEST ]]
 	then
    		LONGEST=${#TEMPLATE}
  	fi
done


for TEMPLATE in $LIST
do
	LENGTH=${#TEMPLATE}	
	UUID=$(xe template-list name-label="$TEMPLATE" params=uuid --minimal)
	(( SPACES = $LONGEST - $LENGTH + 2 ))
	echo -ne "${cyan}$TEMPLATE${off}"
	printf "%*s" "$SPACES"
  	echo -e "${blue}uuid:${off}$UUID"
	if [[ "$MODE" = "verbose" ]] ;then
		DESC=$(xe template-list uuid=$UUID params=name-description --minimal)
		echo -e "$DESC"
		echo ""
	fi
done

