#!/bin/bash
#rmnetwork.sh
#Alpha version .02
#Remove a network from XCP pool
#Author Matthew Spah
#Comments added and made a few changes to main()
#9/05/2012 Adding more comments and noted future changes


set -x
NETWORKUUID=$1

main() {
    

    #first vif_check_disable checks for any active "currently-attached"	VIFs. If true then disable.
    #then we move to vlan_check to see if any VLANs are assigned to the network. If true then move on to vlan_destroy
	#vlan_destroy erased the VLAN and then the conditional destroys the network
	#echo status of the script to the user here?
	
	if vif_check_disable
	then 
		if vlan_check
		then
			if vlan_destroy
			then
				xe network-destroy uuid="$NETWORKUUID"
			fi
		else
			xe network-destroy uuid="$NETWORKUUID"
		fi
	fi
	

}



vlan_check() {

   
    local PIF=$(xe network-list uuid="$NETWORKUUID" params=PIF-uuids --minimal)
    
    # if no PIF is connected to the network then no VLAN configuration is possible
	# return 1.

    if [ -n "$PIF" ]
    then
	    echo "PIF FOUND"
	    local VLANID=$(xe pif-list uuid="$PIF" params=VLAN --minimal)        	    
        
	    # If any VLAN is present exit with 0
		# -1 is the default native VLAN. No tagging is done. So we return with 1.
		# We should probably expand on this in the future. I need some examples of a real world network arcitecture
		
	    if [ "-1" != "$VLANID" ] 
	    then	
		    return 0
	    else
            return 1
        fi
	else
		return 1
    fi
    

}


vif_check_disable() {
    
    # create a list of the VIFs connected to the network
    local VIF_LIST=$(xe vif-list network-uuid="$NETWORKUUID" params=uuid --minimal | sort | sed 's/,/\n/')
    
    # loop through the list checking if they are currently attached
    # looking at this now we can problaby cut this part out by modifying the list :)
    # local VIF_LIST=$(xe vif-list network-uuid="$NETWORKUUID" params=currently-attached --minimal | sort | sed 's/,/\n/')
    
    for VIFNAME in $VIF_LIST
    do
        local ATTACHED=$(xe vif-list uuid="$VIFNAME" params=currently-attached --minimal)
        if [ $ATTACHED = "True" ] 
        then 
            # unplugging the VIF
            if ! xe vif-unplug uuid="$VIFNAME"       
            then 
                echo "Error unplugging $VIFNAME"
				return 1 
            fi
        else
            continue
        fi    
    done ; return 0
    
          
  

}


vlan_destroy() {

    #UNTAGGEDPIF is the pseudo PIF assosiated with the VLAN to be destroyed.
    #we can use that to grab the VLANUUID
    
    local UNTAGGEDPIF=$(xe pif-list network-uuid="$NETWORKUUID" --minimal)
    local VLANUUID=$(xe vlan-list untagged-PIF="$UNTAGGEDPIF" --minimal)
    if xe vlan-destroy uuid="$VLANUUID"    
    then
        return 0
    else
		echo "Error destroying VLAN"
        return 1
    fi
}




main
