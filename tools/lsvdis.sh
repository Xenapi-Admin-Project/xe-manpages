#!/bin/bash

# Shows virtual disk information
# Author: Lisa Nguyen 
# Author: Grant McWilliams (grantmcwilliams.com)
# Version: 0.5
# Date: 

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
NAMELIST=$(xe vdi-list params=name-label --minimal | sed 's/\,/\n/g' | sed '/^$/d' | sort)
for NAME in $NAMELIST "Virtual Disk Image"
do
        if [[ ${#NAME} -gt $NAMELONGEST ]]
        then
                NAMELONGEST=${#NAME}
        fi
done

#get list of VDIs
VDILIST=$(xe vdi-list params=uuid --minimal | sed 's/\,/\n/g' | sed '/^$/d')

#number of spaces
SPACE="10"

#headings
TITLE="Virtual Disk Image"
SIZETITLE="Size"
SRTITLE="Storage Repository"
VMTITLE="Virtual Machine"

#print headings
LENGTH=${#TITLE}	
NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE ))
echo -ne "Virtual Disk Image" ; printf "%*s" "$NAMESPACES"

LENGTH=${#SIZETITLE} ; SIZESPACES=$(( $SPACE - $LENGTH ))
echo -ne "$SIZETITLE" ; printf "%*s" "$SIZESPACES"

LENGTH=${#SRTITLE} ; NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE )) 
echo -ne "$SRTITLE" ; printf "%*s" "$NAMESPACES"

LENGTH=${#VMTITLE} ; NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE ))
echo -ne "$VMTITLE" ; printf "%*s" "$NAMESPACES"

echo ""

for VDIUUID in $VDILIST
do

	#get uuids
	SRUUID=$(xe vdi-param-get uuid=$VDIUUID param-name=sr-uuid)
	VBDUUID=$(xe vbd-list vdi-uuid=$VDIUUID --minimal)

	#if VBD uuid doesn't exist
	if [ -z $VBDUUID ]
	then
		#assign invalid value for vbd uuid (error checking)
		VBDUUID=-1 
		VMNAME="No VM Attached"
	else
		#get VM uuid
		VMUUID=$(xe vbd-param-get uuid=$VBDUUID param-name=vm-uuid)

		if [ -z $VMUUID ]
        	then
			#assign invalid value for vm uuid (error checking)
                	VMUUID=-1
                	VMNAME="No VM Attached"
        	else
			#get VM name
                	VMNAME=$(xe vm-param-get uuid=$VMUUID param-name=name-label)
        	fi
		
	fi 

	#get SR name
	SRNAME=$(xe sr-param-get uuid=$SRUUID param-name=name-label)  

        #get size 
	VDISIZE=$(xe vdi-param-get uuid=$VDIUUID param-name=virtual-size)
	
	#checking valid VDI size
	if [[ $VDISIZE = '-1' ]] ; then
		SRSIZE=0
	fi

	#get VDI sizes
	TOTALSIZE=$(getunit $VDISIZE)
        
	#display VDI uuids
	LENGTH=${#VDIUUID}	
        NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE ))
	cecho "$VDIUUID" cyan
	printf "%*s" "$NAMESPACES"

	#print VDI size
	for COL in $TOTALSIZE
	do
		LENGTH=${#COL}
		SIZESPACES=$(( $SPACE - $LENGTH ))
		cecho "$COL" blue
		printf "%*s" "$SIZESPACES"
	done
	
	#display SR information
	LENGTH=${#SRNAME} 
	NAMESPACES=$(( $NAMELONGEST - $LENGTH + $SPACE ))
	cecho "$SRNAME" blue
	printf "%*s" "$NAMESPACES"

	#display VM information
	LENGTH=${#VMNAME}
        NAMESPACES=$(( $NAMELONGEST - $LENGTH + SPACE))
	cecho "${VMNAME}" blue
        echo ""

done

