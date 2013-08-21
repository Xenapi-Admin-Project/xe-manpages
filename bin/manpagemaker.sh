#!/bin/bash
#12/25/2012 - Matthew Spah
#06/25/2013 - Grant McWilliams
#08/19/2013 - Matthew Spah - Added new functions for the low level commands

oIFS=$IFS
IFS="\n"
SEP="@#@"
PARAMTABLE="$HOME/bin/xe-paramtable.txt"

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

createparamgetdescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""		
	echo "*xe ${XE_COMMAND}* returns the value(s) of a parameter or a map parameter key value for a specified ${OBJECT}"
	echo ""
}

createparamcleardescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""		
	echo "*xe ${XE_COMMAND}* attempts to clear any writable parameter. Use *xe ${OBJECT}-list* and *xe ${OBJECT}-param-list* to identify writable parameters (RW, SRW, MRW)."
	echo ""
}

createparamremovedescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""		
	echo "*xe ${XE_COMMAND}* removes a key from a set parameter or key/value pair from a map parameter. Use *xe ${OBJECT}-list* and *xe ${OBJECT}-param-list* to identify writable set or map parameters (SRW, MRW).﻿"
	echo ""
}

createparamadddescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""		
	echo "*xe ${XE_COMMAND}* adds a key to a set parameter or a key/value pair to a map parameter. Use *xe ${OBJECT}-list* and *xe ${OBJECT}-param-list to identify writable parameters (RW, MRW)."
	echo ""
}

createparamsetdescription()
{
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""		
	echo "*xe ${XE_COMMAND}* sets writable parameters. Use *xe ${OBJECT}-list* and *xe ${OBJECT}-param-list to identify writable parameters (RW, MRW). To append a value to a writable set or map (SRW, MRW) parameter use *xe ${OBJECT}-param-add*"
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
	echo "Output can be filtered by using the *params* parameter and a value (multiple parameters should be separated by commas):"
	echo ""
	echo "- *xe ${XE_COMMAND} params=<PARAM1>*"
	echo "- *xe ${XE_COMMAND} params=<PARAM1,PARAM2,PARAM3>*"
	echo ""
	echo "Output can be filtered by using parameter values and the desired value:"
	echo ""
	echo "- *xe ${XE_COMMAND} <PARAMETER>=<VALUE>*"
	echo ""
	echo "Append --minimal to display values for one parameter on a single line separated by commas:"
	echo ""
	echo "- *xe ${XE_COMMAND} params=\"<PARAMETER>\" --minimal*"
	echo ""
}

createparams(){
	
	PARAMS=$(xe help "$XE_COMMAND" | grep "reqd params" | sed -e "s/^.*reqd params[ \t]*:[ ]//")
	if [[ ! -z "$PARAMS" ]] ;then
		echo ""
		echo "REQUIRED PARAMETERS"
		echo "-------------------"
		echo ""
		IFS=","
		for param in $PARAMS ;	do
			local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
			DESC=$(grep "${XE_COMMAND}${SEP}${PARAMSTRING}${SEP}" "$PARAMTABLE" | awk -F${SEP} '{print $3}')
			echo -e "*$PARAMSTRING*:: \n\t${DESC}" 
		done
	fi
	
	PARAMS=$(xe help "$XE_COMMAND" | grep "optional params" | sed -e "s/^.*optional params[ \t]*:[ ]//")
	if [[ ! -z "$PARAMS" ]] ;then
		echo ""
		echo "OPTIONAL PARAMETERS"
		echo "-------------------"
		echo ""
		IFS=","
		for param in $PARAMS ;	do
			local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
			DESC=$(grep "${XE_COMMAND}${SEP}${PARAMSTRING}${SEP}" "$PARAMTABLE" | awk -F${SEP} '{print $3}')
			echo -e "*$PARAMSTRING*:: \n\t${DESC}" 
		done
		echo ""
		echo "*--minimal*::"
		echo "	Specify --minimal to only show minimal output"
	fi

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

createparamgetpage()
{

	echo "NAME"
	echo "-----"
	echo "xe-${XE_COMMAND} - Returns a parameter for a ${OBJECT}"	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe ${XE_COMMAND}*  uuid=<${OBJECTUPPER} UUID> param-name=<PARAMETER> [ param-key=<PARAMETER KEY> ]"
	createparamgetdescription
	createparams 
	echo ""
	echo "EXAMPLES"
	echo "--------"
	echo ""
	createseealso
}

createparamaddpage()
{

	echo "NAME"
	echo "-----"
	echo "xe-${XE_COMMAND} - Add a key to a parameter for a ${OBJECT}"	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe ${XE_COMMAND}*  uuid=<${OBJECTUPPER} UUID> param-name=<PARAMETER> [ param-key=<SET PARAMETER KEY> ] [ <MAP PARAMETER KEY>=<VALUE> ]"
	createparamadddescription
	createparams 
	echo ""
	echo "EXAMPLES"
	echo "--------"
	echo ""
	createseealso
}

createparamsetpage()
{

	echo "NAME"
	echo "-----"
	echo "xe-${XE_COMMAND} - Set parameters for a ${OBJECT}"	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe ${XE_COMMAND}*  uuid=<${OBJECTUPPER} UUID> [ <PARAMETER>=<VALUE> ] [ <MAP PARAMETER>:<MAP PARAMETER KEY>=<VALUE> ]"
	createparamsetdescription
	createparams 
	echo ""
	echo "EXAMPLES"
	echo "--------"
	echo ""
	createseealso
}

createparamclearpage()
{

	echo "NAME"
	echo "-----"
	echo "xe-${XE_COMMAND} - Clears a specific writable parameter for a ${OBJECT}"	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe ${XE_COMMAND}* uuid=<${OBJECTUPPER} UUID> param-name=<PARAMETER NAME>"
	createparamcleardescription
	createparams 
	echo ""
	echo "EXAMPLES"
	echo "--------"
	echo ""
	createseealso
}

createparamremovepage()
{

	echo "NAME"
	echo "-----"
	echo "xe-${XE_COMMAND} - Removes a key or key/value pair from a ${OBJECT}"	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe ${XE_COMMAND}* uuid=<${OBJECTUPPER} UUID> param-name=<PARAMETER NAME> param-key=<PARAMETER KEY>"
	createparamremovedescription
	createparams 
	echo ""
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
	echo "To display all parameters for all ${OBJECTUPPER}s:"
	echo ""
	echo "- *xe ${XE_COMMAND}* params=\"all\""
	echo ""
	echo "To display all parameters for a specific ${OBJECTUPPER}:"
	echo ""
	echo "- *xe ${XE_COMMAND}* uuid=<${OBJECT} UUID> params=\"all\""
	echo ""
	echo "To display <PARAMETER> for a specific ${OBJECTUPPER}:"
	echo ""
	echo "- *xe ${XE_COMMAND}* uuid=<${OBJECT} UUID> params=\"VIF-uuids\""
	echo ""
	echo "To display the <PARAMETER> and <PARAMETER> parameters of all ${OBJECTUPPER}s  with a <PARAMETER> of <VALUE>:"
	echo ""
	echo "- *xe ${XE_COMMAND}* <PARAMETER>=<VALUE> params=\"<MULTIPLE PAMETERS>\""
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
elif [[ $OBJTYPE = "param-set" ]] ;then
	createparamsetpage
elif [[ $OBJTYPE = "param-remove" ]] ;then
	createparamremovepage
elif [[ $OBJTYPE = "param-clear" ]] ;then
	createparamclearpage
elif [[ $OBJTYPE = "param-get" ]] ;then
	createparamgetpage
elif [[ $OBJTYPE = "param-add" ]] ;then
	createparamaddpage
else
	createpage
fi
createfooter



