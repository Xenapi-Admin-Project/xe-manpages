#!/bin/bash
#rmnetwork.sh
#Remove a network from XCP pool
#Author Matthew Spah
#8/26/2012
#Alpha version .01
#Comments added and made a few changes to main()
#8/28/2012
#still much more work to be done
#Caution: Use at own RISK


set -x
NETWORKUUID=$1

main() {
    
    #first we check to see if a VLAN is present on the VLAN
	#If a VLAN is present we move to check for any active VIFS
	# VIFS are then disable and then the VLAN is destroyed.
	# From there the network is destroyed
	#I'm going to change the logic on this
	#I don't see why we have to check for the VLAN first. We should be able to check for Active VIFS first
    # There might actually be a correct order to take down networks
	# look into it
	
	
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
	
   # if vlan_check
   # then
   #    if vif_check_disable
   #    then 
   #         if vlan_destroy                        
   #         then
   #             xe network-destroy uuid="$NETWORKUUID"             
   #         fi        
   #     fi    
   # else
   #     if vif_check_disable
   #     then 
   #         xe network-destroy uuid="$NETWORKUUID"
   #     fi
   # fi

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
		# -1 is the default native VLAN. No tagging is done. So we turn with 1.
		# We should probably expand on this in the future
		
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
    
    local VIF_LIST=$(xe vif-list network-uuid="$NETWORKUUID" params=uuid --minimal | sort | sed 's/,/\n/')
    for VIFNAME in $VIF_LIST
    do
        local ATTACHED=$(xe vif-list uuid="$VIFNAME" params=currently-attached --minimal)
        if [ $ATTACHED = "True" ] 
        then 
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
