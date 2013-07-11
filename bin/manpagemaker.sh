#!/bin/bash
#12/25/2012 - Matthew Spah
#06/25/2013 - Grant McWilliams

oIFS=$IFS
IFS="\n"

createheader()
{
	echo "XE(1)"
	echo "======="
	echo ":doctype: manpage"
	echo ":man source:   xe $XE_COMMAND"
	echo ":man version:  {1}"
	echo ":man manual:   xe $XE_COMMAND manual"
	echo ""
}

createdescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""	
}

createlistdescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""	
	echo "*xe ${XE_COMMAND}* displays ${OBJECTUPPER}s and their parameters."
	echo ""
	echo "Output can be filtered by using the *params* parameter and a value (multiple parameters should be separated by commas): ::"
	echo "	*xe ${XE_COMMAND} params=<PARAM1>* +"
	echo "	*xe ${XE_COMMAND} params=<PARAM1,PARAM2,PARAM3>*"
	echo ""
	echo "Output can be filtered by using parameter values and the desired value: ::"
	echo "	*xe ${XE_COMMAND} <PARAMETER>=<VALUE>*"
	echo ""
	echo "Append --minimal to display values for one parameter outputted on a single line with results separated by commas: ::"
	echo "	*xe ${XE_COMMAND} params=\"<PARAMETER>\" --minimal*"
	echo ""
}

createparams(){
	echo ""
	PARAMTYPES="reqd optional"
	for TYPE in $PARAMTYPES ;do
		PARAMS=$(xe help "$XE_COMMAND" | grep "$TYPE params" | sed -e "s/^.*$TYPE params[ ]:[ ]//")
		if [[ -z "$PARAMS" ]] ;then
			continue
		fi
		case $TYPE in
			"reqd") 
				echo "REQUIRED PARAMETERS"
				echo "-------------------"
				echo ""
			;;
		"optional") 
				echo "OPTIONAL PARAMETERS"
				echo "-------------------"
				echo "*all*::"
				echo "	Display all parameter values"
				echo ""
			;;
		esac
		IFS=","
		for param in $PARAMS ;	do
			local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
			case $PARAMSTRING in
				"params") echo -e "*$PARAMSTRING*:: \n\tParameter(s) to filter on" ;;
				"uuid") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} UUID" ;;
				"name-label") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} label" ;;
				"name-description") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} description" ;;
				"other-config") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} other-config parameters" ;;
				"tags") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} tags" ;;
				"dom-id") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} Domain ID" ;;
				"allowed-operations") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} allowed operations" ;;
				"current-operations") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} current operations" ;;
				"blocked-operations") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} blocked operations" ;;
				"power-state") echo -e "*$PARAMSTRING*:: \n\t${OBJECTUPPER} power state" ;;
				"xenstore-data") echo -e "*$PARAMSTRING*:: \n\tXenstore data" ;;
				"sr-uuid") echo -e "*$PARAMSTRING*:: \n\tStorage Repository UUID" ;;
				"sr-name-label") echo -e "*$PARAMSTRING*:: \n\tStorage Repository name label" ;;
				"vm-uuid") echo -e "*$PARAMSTRING*:: \n\tVirtual Machine UUID" ;;
				"vm-name-label") echo -e "*$PARAMSTRING*:: \n\tVirtual Machine name label" ;;
				"vdi-uuid") echo -e "*$PARAMSTRING*:: \n\tVirtual Disk Image UUID" ;;
				"vdi-name-label") echo -e "*$PARAMSTRING*:: \n\tVirtual Disk Image name label" ;;
				"host-uuid") echo -e "*$PARAMSTRING*:: \n\tHost UUID" ;;
				"host-name-label") echo -e "*$PARAMSTRING*:: \n\tHost name label" ;;
				"network-uuid") echo -e "*$PARAMSTRING*:: \n\tNetwork UUID" ;;
				"network-name-label") echo -e "*$PARAMSTRING*:: \n\tNetwork name label" ;;
				"pool-uuid") echo -e "*$PARAMSTRING*:: \n\tPool UUID" ;;
				"pool-name-label") echo -e "*$PARAMSTRING*:: \n\tPool name label" ;;
				"VIF-uuids") echo -e "*$PARAMSTRING*:: \n\tVirtual Network Interface UUIDs" ;;
				"PIF-uuids") echo -e "*$PARAMSTRING*:: \n\tPhysical Network Interface UUIDs" ;;
				"MTU") echo -e "*$PARAMSTRING*:: \n\tNetwork Interface Maximum Transmission Unit" ;;
				"MAC") echo -e "*$PARAMSTRING*:: \n\tNetwork Interface hardware address" ;;
				"VLAN") echo -e "*$PARAMSTRING*:: \n\tVLAN tag ID" ;;
				"IP") echo -e "*$PARAMSTRING*:: \n\tIP Address" ;;
				"DNS") echo -e "*$PARAMSTRING*:: \n\tDomain Name Server Address" ;;
				"netmask") echo -e "*$PARAMSTRING*:: \n\tNetwork Mask" ;;
				"gateway") echo -e "*$PARAMSTRING*:: \n\tIPv4 Default Gateway" ;;
				"IPv6-gateway") echo -e "*$PARAMSTRING*:: \n\tIPv6 Default Gateway" ;;
				*) echo -e "*$PARAMSTRING*:: \n" ;;
			esac
		done
		case $TYPE in
			"optional") 
				echo ""
				echo "*--minimal*::"
				echo "	Specify --minimal to only show minimal output"
			;;
		esac
	done
}

createpage()
{
	echo ""
	echo "NAME"
	echo "----"
	echo ""
	echo "${XE_COMMAND} -"
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	createdescription
	createparams
	echo "EXAMPLES"
	echo "--------"
	echo ""
	createseealso
}

createlistpage()
{

	echo "NAME"
	echo "-----"
	echo "xe-${XE_COMMAND} - Displays ${OBJECTUPPER}s"	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe ${XE_COMMAND}*  [ params=<PARAMETER> ] [--minimal]"
	createlistdescription
	createparams 
	echo ""
	echo "EXAMPLES"
	echo "--------"
	echo "To display all parameters for all ${OBJECTUPPER}s *: ::"
	echo "	*xe ${XE_COMMAND}* params=\"all\""
	echo "To display all parameters for a specific ${OBJECTUPPER} *: ::"
	echo "	*xe ${XE_COMMAND}* uuid=<${OBJECT} UUID> params=\"all\""
	echo "To display <PARAMETER> for a specific ${OBJECTUPPER} : ::"
	echo "	*xe ${XE_COMMAND}* uuid=<${OBJECT} UUID> params=\"VIF-uuids\""
	echo "To display the <PARAMETER> and <PARAMETER> parameters of all ${OBJECTUPPER}s  with a <PARAMETER> of <VALUE>: ::"
	echo "	*xe ${XE_COMMAND}* <PARAMETER>=<VALUE> params=\"<MULTIPLE PAMETERS>\""
	createseealso
}

createseealso()
{
	
	echo ""
	echo "SEE ALSO"
	echo "--------"
	echo "*xe help ${XE_COMMAND}*,"
	echo ""
}

createfooter()
{
	echo "AUTHORS"
	echo "-------"
	echo "Manpage Author(s): ::"
	echo "$COPYNAME $COPYEMAIL" # add user input options for authors
	echo ""
	echo "BUGS"
	echo "----"
	echo "For guidelines on submitting bug reports see http://wiki.xen.org/wiki/Reporting_Bugs_against_XCP. Submit bugs and general questions to xen-api@lists.xen.org."
	echo ""
	echo "COPYRIGHT"
	echo "---------"
	echo "Copyright \(C)  $(date +"%Y") - $COPYNAME"
	echo "Permission is granted to copy, distribute and/or modify this document under the terms of the GNU Free Documentation License, Version 1.3 or any later version published by the Free Software Foundation; with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts. A copy of the license is included in the section entitled \"GNU Free Documentation License\""
}

XE_COMMAND="$1"
HELPDISPLAY=$(xe help "$XE_COMMAND")

OBJECT=${XE_COMMAND%%-*}
OBJTYPE=${XE_COMMAND#*-}
OBJECTUPPER=$(echo $OBJECT | tr 'a-z' 'A-Z')

# To automate the insertion of copywrite information put the following two lines
# with your information in $HOME/.manpagemaker_creds.txt 
COPYEMAIL="<manpage author email address>"
COPYNAME="<manpage author name>"

if [[ -e "$HOME/.manpagemaker_creds.txt" ]] ;then
	source "$HOME/.manpagemaker_creds.txt"
fi

createheader
if [[ $OBJTYPE = "list" ]] ;then
	createlistpage
else
	createpage
fi
createfooter



