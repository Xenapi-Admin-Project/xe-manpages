#!/bin/bash
# Matthew Spah 08/27/2013
# Fill in the common parameter desriptions found in xe-paramtable.txt
set -x

# Wish list
# * add a function for list commands (e.g list(){} )
# * interface this script with Grants makeparamtable.sh
# * add more universal parameter descriptions to param-check, and param-set.



# PARAMTABLE is path to xe-paramtable.txt, currently this is static and the file must be present in the same directory
# Add argument option in the future
PARAMTABLE=xe-paramtable.txt
oIFS=$IFS
IFS=$'\n'


# low level param-list commands (e.g xe-host-param-list, xe-pif-param-list)
param-list(){

	OBJ=${1^^}
	
	case "$2" in 
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list* to obtain a list of $1 UUIDs."
		;;
		name-label)
			echo "Set name of $OBJ"
		;;
		name-description)
			echo "Set name-description of $OBJ"
		;;
		
	esac
	
}


# low level param-get commands (e.g xe-host-param-get, xe-vif-param-get)
param-get(){

	OBJ=${1^^}


	case "$2" in 
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list* to obtain a list of $OBJ UUIDs."
		;;
		
		param-key)
			echo "The $OBJ map parameter key value to return"
		;;
		
		param-name)
			echo "The $OBJ parameter to return"
		;;
	esac	
	
}

# low level param-set commands (e.g xe-vif-param-set, xe-vid-param-set)
param-set(){
	OBJ=${1^^}

	case "$2" in 
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list* to obtain a list of $OBJ UUIDs."
		;;
		
	esac
	
}

# low level param-add commands (e.g xe-network-param-add, xe-host-param-add)
param-add(){
	OBJ=${1^^}
	
	case "$2" in 
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list* to obtain a list of $OBJ UUIDs."
		;;
		
		param-name)
			echo "Parameter to have key or key/value pair added - Use *xe $OBJ-param-list* to obtain a list of $1 parameters."
		;;
		
		param-key)
			echo "Key to be added to a set parameter (SRW)."
		;;
	esac	
	
}


param-remove(){
	OBJ=${1^^}
	
	case "$2" in 
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list* to obtain a list of $OBJ UUIDs."
		;;
		
		param-name)
			echo "Parameter that contains keys or key/value pairs. (e.g. other-config)."
		;;
		
		param-key)
			echo "Key or key/value pair to be removed."
		;;
	esac
	
}

# low level param-clear commands (e.g xe-pif-param-clear, xe-vm-param-clear)
param-clear(){
	
	OBJ=${1^^}

	case "$2" in 
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list* to obtain a list of $OBJ UUIDs."
		;;
		param-name)
			echo "Writable parameter to be cleared. (e.g. other-config)."
		;;
	esac
	
	
}


# high level XE commands (e.g xe-vm-clone, xe-pif-create)
param-check(){
	OBJ=${1^^}
	
	case "$2" in
		uuid)
			echo "$OBJ UUID - Use *xe $OBJ-list to obtain a list of $OBJ UUIDs."
		;;
		\<host-selectors\>)
			echo "Parameters to select host(s) - use *xe host-list params=all* to get a list of host parameters to filter on."
		;;
	
		\<vm-selectors\>)
			echo "Parameters to select VM(s) - use *xe vm-list params=all* to get a list of VM parameters to filter on."
		;;
		sr-uuid)
			echo "Desired storage repository UUID - use *xe sr-list* to get a list of storage repositories"
		;;
		host-uuid)
			echo "Host UUID - Use *xe host-list* to obtain a list of host UUIDs."
		;;
		vm-uuid)
			echo "Virtual machine UUID - Use *xe vm-list* to obtain a list of VM UUIDs"
		;;
		force)
			echo "Force operation"
		;;
		*)
			return 1
		;;

	esac
	
}


listcommand(){
	OBJ=${1^^}
	
	case "$2" in 
		uuid)
			echo "Display $OBJ UUIDs"
		;;
		
		name-label)
			echo "Display $OBJ name-labels"
		;;
		
		name-description)
			echo "Display $OBJ name-descriptions"
		;;
		*)
			return 1
		;;
	esac
}

# loop through each line of $PARAMTABLE
for line in $(cat $PARAMTABLE) ; do

	# Grabbing each field of PARAMTABLE, @#@ is the field delimiter 
	COMMAND=$(echo "$line" | awk -F"@#@" '{ print $1 }')
	PARAMNAME=$(echo "$line" | awk -F"@#@" '{ print $2 }')
	PARAMDESCRIPTION=$(echo "$line" | awk -F"@#@" '{ print $3 }')

	
	
	# using horrible pattern matching to figure out the command type, this could use improving.
	# If $COMMAND matches to one of the statements below,.the correct function is launched with command arugments passed to it
	# it will return the parameter description, and then the new line is sent to STDOUT.
	case "$COMMAND" in		
		*-param-list)
		NEWPARAMDESCRIPTION=$(param-list "${COMMAND%%-*}" "$PARAMNAME")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		;;
		
		*-param-get)
		NEWPARAMDESCRIPTION=$(param-get "${COMMAND%%-*}" "$PARAMNAME")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		;;
		
		*-param-set)
		NEWPARAMDESCRIPTION=$(param-set "${COMMAND%%-*}" "$PARAMNAME")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		;;
		
		*-param-add)
		NEWPARAMDESCRIPTION=$(param-add "${COMMAND%%-*}" "$PARAMNAME")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		;;
		
		*-param-remove)
		NEWPARAMDESCRIPTION=$(param-remove "${COMMAND%%-*}" "$PARAMNAME")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		;;
		
		*-param-clear)
		NEWPARAMDESCRIPTION=$(param-clear "${COMMAND%%-*}" "$PARAMNAME")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		;;

		*-list)
		NEWPARAMDESCRIPTION=$(listcommand "${COMMAND%%-*}" "$PARAMNAME")
		if [[ $? -eq 0 ]]; then
			echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		else
			echo "$line"
		fi		
		;;
		
		# if $COMMAND doesn't match any of the above
		*)
		NEWPARAMDESCRIPTION=$(param-check "${COMMAND%%-*}" "$PARAMNAME")
		if [[ $? -eq 0 ]]; then
			echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARAMDESCRIPTION}"
		else
			echo "$line"
		fi
		;;
	esac 

done
