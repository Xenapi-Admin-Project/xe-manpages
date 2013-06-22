#!/bin/bash
#12/25/2012 .
#set -x
#
oIFS=$IFS
IFS="\n"

XE_COMMAND=$1
HELPDISPLAY=$(xe help "$XE_COMMAND")


# I would like to turn oparams and reparams into arrays
oparams(){
	IFS=","
	local LIST=$(echo "$HELPDISPLAY" | grep "optional params" | sed -e 's/optional params//' | sed -e 's/^[ \t]*//' | sed -e 's/://' | sed 's/^[ \t]*//')
	# grepping the xe help display and creating a listwith its contents
	for param in $LIST
	do
		local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
		echo "*$PARAMSTRING*::"
		echo ""
	done ; IFS=$oIFS
}

reparams(){
	# grepping the xe help display and creating a list with its contents
	local LIST=$(echo "$HELPDISPLAY" | grep "reqd params" | sed -e 's/reqd params//' | sed -e 's/^[ \t]*//' | sed -e 's/://' | sed 's/^[ \t]*//')
	IFS=","
	for param in $LIST
	do	
		local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
		echo "*$PARAMSTRING*::"
		echo ""
	done ; IFS=$oIFS
}


createpage()
{
	echo "XE(1)"
	echo "======="
	echo ":doctype: manpage"
	echo ":man source:   xe $XE_COMMAND"
	echo ":man version:  {1}"
	echo ":man manual:   xe $XE_COMMAND manual"	
	#
	echo ""
	echo "NAME"
	echo "----"
	echo ""
	echo "$XE_COMMAND -"
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo ""
	echo "REQUIRED PARAMETERS"
	echo "-------------------"
	echo ""
	# required params
	reparams
	echo "OPTIONAL PARAMETERS"
	echo "-------------------"
	echo ""
	# optional params
	oparams
	echo "EXAMPLES"
	echo "--------"
	echo ""
	echo "SEE ALSO" # Parsing a database of XE subcommands using pattern matching for the see also section
	echo "--------"
	echo ""
	echo "AUTHORS"
	echo "-------"
	echo "Manpage Author(s): ::"
	echo "Example User <username@mail.com>" # add user input options for authors
	echo ""
	echo "BUGS"
	echo "----"
	echo "See http://wiki.xen.org/wiki/Reporting_Bugs_against_XCP on how to send bug reports, Send bugs to xen-devel@lists.xen.org. General questions can be sent to xen-api@lists.xen.org."
	echo ""
	echo ""
	echo "COPYRIGHT"
	echo "---------"
	echo "Copyright \(C) 2013 - Example Name"
}

createlistpage()
{
	# Building the heading
	echo "XE(1)"
	echo "======="
	echo ":doctype: manpage"
	echo ":man source:   xe $XE_COMMAND"
	echo ":man version:  {1}"
	echo ":man manual:   xe $XE_COMMAND manual"
	echo ""
	echo "NAME"
	echo "-----"
	echo "xe-$XE_COMMAND - Displays  parameters."	
	echo ""
	echo "SYNOPSIS"
	echo "--------"
	echo "*xe $XE_COMMAND*  [ params=<PARAMETER> ] [--minimal]"
	echo ""
	echo "DESCRIPTION"
	echo "-----------"
	echo "*xe $XE_COMMAND* displays <OBJECT> and their parameters."
	echo ""
	echo "Output can be filtered by using the *params* parameter and a value (separate multiple parameters with commas): ::"
	echo "	*xe $XE_COMMAND params=<ONE PARAMETER>* +"
	echo "	*xe $XE_COMMAND params=<MULTIPLE PARAMETERS>*"
	echo ""
	echo "Output can be filtered by using parameter values and the desired value: ::"
	echo "	*xe $XE_COMMAND <PARAMETER>=<VALUE>*"
	echo ""
	echo "Append --minimal to display values for one parameter on a single line separated by commas: ::"
	echo "	*xe $XE_COMMAND params=\"<PARAMETER>\" --minimal*"
	echo ""
	echo "OPTIONAL PARAMETERS"
	echo "-------------------"
	echo "*all*::"
	echo "	Display all parameter values"
	echo ""
	oparams
	echo ""
	echo "*--minimal*::"
	echo "	Specify --minimal to only show minimal output"
	echo ""
	echo "EXAMPLES"
	echo "--------"
	echo "To display all parameters for all *: ::"
	echo "	*xe <OBJECT>-list* params=\"all\""
	echo "To display all paramters for a specific *: ::"
	echo "	*xe <OBJECT>-list* uuid=<OBJECT UUID> params=\"all\""
	echo "To display <PARAMETER> for a specific <OBJECT>: ::"
	echo "	*xe <OBJECT>-list* uuid=<NETWORK UUID> params=\"VIF-uuids\""
	echo "To display the <PARAMETER> and <PARAMETER> parameters of all <OBJECT> with a <PARAMETER> of <VALUE>: ::"
	echo "	*xe <OBJECT>-list* <PARAMETER>=<VALUE> params=\"<MULTIPLE PAMETERS>\""
	echo ""
	echo "SEE ALSO"
	echo "--------"
	echo "*xe help <OBJECT>-list*,"
	echo ""
	echo "AUTHORS"
	echo "-------"
	echo "Manpage Author(s): ::"
	echo "Example User <username@mail.com>" # add user input options for authors
	echo ""
	echo "BUGS"
	echo "----"
	echo "For guidelines on submitting bug reports see http://wiki.xen.org/wiki/Reporting_Bugs_against_XCP. Submit bugs and general questions to xen-api@lists.xen.org."
	echo ""
	echo "COPYRIGHT"
	echo "---------"
	echo "Copyright \(C)  2013 - <manpage author name>"
	echo "Permission is granted to copy, distribute and/or modify this document under the terms of the GNU Free Documentation License, Version 1.3 or any later version published by the Free Software Foundation; with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts. A copy of the license is included in the section entitled \"GNU Free Documentation License\""
}

if echo "$XE_COMMAND" | grep -e '.*-list$' ;then
	createlistpage
else
	createpage
fi


