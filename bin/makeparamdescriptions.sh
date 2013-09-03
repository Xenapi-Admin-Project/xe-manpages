#!/bin/bash
# Matthew Spah 08/27/2013
# Fill in the common parameter desriptions found in xe-paramtable.txt


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
		NEWPARDESCRIPTION=$(param-list "${COMMAND%%-*}" "$PARAMTYPE")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		;;
		
		*-param-get)
		NEWPARDESCRIPTION=$(param-get "${COMMAND%%-*}" "$PARAMTYPE")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		;;
		
		*-param-set)
		NEWPARDESCRIPTION=$(param-set "${COMMAND%%-*}" "$PARAMTYPE")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		;;
		
		*-param-add)
		NEWPARDESCRIPTION=$(param-add "${COMMAND%%-*}" "$PARAMTYPE")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		;;
		
		*-param-remove)
		NEWPARDESCRIPTION=$(param-remove "${COMMAND%%-*}" "$PARAMTYPE")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		;;
		
		*-param-clear)
		NEWPARDESCRIPTION=$(param-clear "${COMMAND%%-*}" "$PARAMTYPE")
		echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		;;
		
		# If $COMMAND can't be matched to any of the statements above, then it is passed to param-check. This is a general function that looks up the parameters found in high level XE commands (xe-pif-introduce, xe-vif-create)
		*)
		NEWPARDESCRIPTION=$(param-check "${COMMAND%%-*}" "$PARAMNAME")
		if [[ $? -eq 0 ]]; then
			echo "${COMMAND}@#@${PARAMNAME}#@#${NEWPARDESCRIPTION}"
		else
			echo "$line"
		fi
		;;
	esac 

done
