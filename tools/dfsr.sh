#!/bin/bash

# Shows storage repository size
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: July 25, 2012

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


IFS=$'\n'
NAMELONGEST=0
setcolors

while getopts :dh opt
do
        case $opt in
                d) set -x ;;
                h) syntax ;;
                \?) echo "Unknown option"; syntax ;;
        esac
done
shift $(($OPTIND - 1))


# Get longest HOST name
NAMELIST=$(xe sr-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
for NAME in $NAMELIST "Storage Repository"
do
        if [[ ${#NAME} -gt $NAMELONGEST ]]
        then
                NAMELONGEST=${#NAME}
        fi
done

SRNAMES=$(xe sr-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)

SPACE="10"
TITLE="Storage Repository"
USEDTITLE="Used"
SIZETITLE="Size"
AVAILTITLE="Avail"
FREETITLE="Full"
TYPETITLE="SR Type"

LENGTH=${#TITLE}	
NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE ))
echo -ne "Storage Repository" ; printf "%*s" "$NAMESPACES"

LENGTH=${#SIZETITLE} ; SIZESPACES=$(( $SPACE - $LENGTH ))
echo -ne "$SIZETITLE" ; printf "%*s" "$SIZESPACES"

LENGTH=${#USEDTITLE} ; SIZESPACES=$(( $SPACE - $LENGTH ))
echo -ne "$USEDTITLE" ; printf "%*s" "$SIZESPACES"

LENGTH=${#AVAILTITLE} ; SIZESPACES=$(( $SPACE - $LENGTH ))
echo -ne "$AVAILTITLE" ; printf "%*s" "$SIZESPACES"

LENGTH=${#FREETITLE} ; SIZESPACES=$(( $SPACE - $LENGTH ))
echo -ne "$FREETITLE" ; printf "%*s" "$SIZESPACES"

LENGTH=${#TYPETITLE} ; SIZESPACES=$(( $SPACE - $LENGTH ))
echo -e "$TYPETITLE" 

for REPO in $SRNAMES
do
	SRUUID=$(xe sr-list name-label="$REPO" --minimal)
	SRUSED=$(xe sr-param-get uuid=$SRUUID param-name=physical-utilisation)
	SRSIZE=$(xe sr-param-get uuid=$SRUUID param-name=physical-size)
	SRTYPE=$(xe sr-param-get uuid=$SRUUID param-name=type)
	if [[ $SRUSED = '-1' || $SRSIZE = '-1' ]] ; then
		SRUSED=0 ; SRSIZE=0
	fi
	if [ $SRSIZE -gt 0 ] ;then
		MEMPERCENT=$(echo "scale=2; $SRUSED / $SRSIZE * 100" | bc | sed s/\\.[0-9]\\+//)
	else
		MEMPERCENT="100"	
	fi
	
	TOTALSIZE=$(getunit $SRSIZE)
	USEDSIZE=$(getunit $SRUSED)
	TEMPSIZE=$(( $SRSIZE - $SRUSED))
	FREESIZE=$(getunit $TEMPSIZE)
        
	LENGTH=${#REPO}	
        NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE ))
	cecho "$REPO" cyan
	printf "%*s" "$NAMESPACES"

	for COL in $TOTALSIZE $USEDSIZE $FREESIZE
	do
		LENGTH=${#COL}
		SIZESPACES=$(( $SPACE - $LENGTH ))
		cecho "$COL" blue
		printf "%*s" "$SIZESPACES"
	done
	
	LENGTH=${#MEMPERCENT}
	SIZESPACES=$(( $SPACE - $LENGTH ))
	cecho "${MEMPERCENT}%" blue 
	printf "%*s" "$SIZESPACES"
	
	cecho "${SRTYPE}" blue 
	echo ""
done

