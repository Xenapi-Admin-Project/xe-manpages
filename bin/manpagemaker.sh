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
	#if [ -n "$param" ] ; then # checking if our list is blank 
		local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
		echo "*$PARAMSTRING*::"
		echo ""
	#fi
done ; IFS=$oIFS


}

reparams(){
# grepping the xe help display and creating a list with its contents
local LIST=$(echo "$HELPDISPLAY" | grep "reqd params" | sed -e 's/reqd params//' | sed -e 's/^[ \t]*//' | sed -e 's/://' | sed 's/^[ \t]*//')
IFS=","
for param in $LIST
do	
	#param=$(echo "$param" | sed '/^$/d')
	#if [ -n "$param" ] ; then # checking if our list is blank
		local PARAMSTRING=$(echo "$param" | sed -e 's/^[ \t]*//')
		echo "*$PARAMSTRING*::"
		echo ""
	#fi
done ; IFS=$oIFS
}


# echoing manpage template


# add user input options for authors

# Building the heading
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
echo "Matthew Spah <spahmatthew@gmail.com>" # add user input options for authors
echo ""
echo "BUGS"
echo "----"
echo "See http://wiki.xen.org/wiki/Reporting_Bugs_against_XCP on how to send bug reports, Send bugs to xen-devel@lists.xen.org. General questions can be sent to xen-api@lists.xen.org."
echo ""
echo ""
echo "COPYRIGHT"
echo "---------"
echo "Copyright \(C) 2012 - Matthew Spah"


# capture this output so the user doesn't have to redirect 
