#!/bin/bash
#mknetwork.sh
#Author: Matthew Spah
#verison .01
#09/1/2012
#CAUTION: Use at own risk. 

set -x

while getopts :n:l:p:v:d: opt
do
	case "$opt" in
	n) 
		NAMELABEL=$OPTARG ;;
	l)
		VLAN_ID=$OPTARG ;;
	p)
		PIF=$OPTARG ;;
	v)
		VM=$OPTARG ;; #I think I'll need to make an arrary
	*)
		echo "Option not found" ;;
	esac
done 


mkpoolvlan() {
    
    VLANUUID=$(xe pool-vlan-create network-uuid=$NETWORKUUID pif-uuid=$PIF vlan=$VLAN_ID)
    if [ -n "$VLANUUID" ]
    then
        return 0
    else 
        return 1
    fi 
}




mkvifs() {
    
    DEV=$(xe vif-list vm-uuid=$VM params=device --minimal | sort | sed 's/,/\n/' | tail -1)   
    
    if [ -n $DEV]
    then 
        VIFUUID=$(xe vif-create vm-uuid="$VM" device=0 network-uuid="$NETWORKUUID")
    else 
        DEV=$[ "$DEV" + 1 ]
        VIFUUID=$(xe vif-create vm-uuid="$VM" device="$DEV" network-uuid="$NETWORKUUID")
    fi
    
    if [ -n $VIFUUID ]
    then
        return 0
    else
        return 1
    fi
    
   
}


NETWORKUUID=$(xe network-create name-label=$NAMELABEL) 

if [ -n "$NETWORKUUID" ] ; then
    if mkpoolvlan ; then
       
        if mkvifs ; then 
       
            echo $VLANUUID $NETWORKUUID $VIFUUID
       
        fi
    
    fi

fi


    




