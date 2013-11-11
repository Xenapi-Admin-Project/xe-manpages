#!/bin/bash

# Converts source documents to pdf, man or html
# Created by Grant McWilliams
# Version 0.1
# October 22, 2012

# Edit by Matthew Spah
# Oct 14, 2013
# Version 0.2
# added the -r option to render the entire RELEASE Directory


setup()
{
	
	DOCDIR=$(find_git)
		
	# Added 10/15/2013 
	# If we can't find the repository exit
	if [[ ! -d "$DOCDIR" ]] ;then
		echo "Unable to locate GIT xe-manpages directory"
		echo "Have you cloned the xe-manpages repostory?"
		exit 1
	fi
	
	SRCDOCDIR="$DOCDIR/docs/source/asciidoc"
	RELEASE="$SRCDOCDIR/RELEASE/" #Added 10/14/2013
	BINDIR="$DOCDIR/bin" 
	XSLPOINTER="$BINDIR/XSLManpages/manpages/docbook.xsl" #Added 10/14/2013
	TMPDIR=$(mktemp -d)
	PROGNAME=$(basename $0)
	
	# Adding so if you don't select the PDF option, it won't ask you if you need to create a PDF dir
	case "$FORMAT" in
		pdf) PDFDOCDIR="$DOCDIR/docs/pdf" ;;
		manpage) MANDOCDIR="$DOCDIR/docs/manpage" ;;
	esac
	
	
	for DIR in "$SRCDOCDIR" "$MANDOCDIR" "$PDFDOCDIR" ; do
		
		# Added 10/30/2013
		if [[ -z "$DIR" ]] ;then # skip over variable if it is white space 
			continue 
		fi
				
		if [[ ! -d "$DIR" ]] ;then
			echo "$DIR doesn't exist - maybe git isn't set up"
			if yesno "Do you want to create $DIR"
			then
				mkdir -p "$DIR"	
			else
				exit 1
			fi
		fi
	done

	# Added 10/14/2013
	if [[ ! -f "$XSLPOINTER" ]] ;then 
		echo "XenAPI Manpage XSL Stylesheets not installed - exiting"
		exit 1
	fi


	if ! which a2x &> /dev/null ; then
		echo "a2x command not installed - exiting"
		exit 1
	fi

	
	if ! which fop &> /dev/null ; then
		echo "The fop command not installed - $PROGNAME will not be able to create pdf documents"
	fi


	if ! which xsltproc &> /dev/null ; then
		echo "The xsltproc command not installed - $PROGNAME will not be able to process documents"
		exit 1
	fi

}

# Looking for the xe-manpage repository in Users home directory
find_git()
{
	GITDIRS=$(find $HOME -name "*.git" | grep 'xe-manpages/.git')
	PS3='Please enter your choice for default GIT xe-manpage directory: '
	select opt in ${GITDIRS[@]}
	do
		echo "${opt%/.git}"
		break ;
	done

}

syntax()
{
	echo ""
	echo "$PROGNAME [options] <asciidoc file>"
	echo "options:"
	echo "-m	make manpage document type"
	echo "-p	make pdf document type"
	echo ""
}

makeman()
{	
	FILE="$1"
	echo "Converting $FILE to manpage"
	cp -f "$FILE" "$TMPDIR"
	TMPFILE=$(basename "$FILE") 
	a2x --xsl-file="$XSLPOINTER" --doctype manpage -f manpage "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
	echo ""
}


makepdf()
{	
	FILE="$1"
	echo "Converting $FILE to pdf"
	cp -f "$FILE" "$TMPDIR"
	TMPFILE=$(basename "$FILE")
	a2x -f pdf --asciidoc-opts='-a lang=en -v -b  docbook -d manpage' "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
	#a2x -f pdf -dbook --fop "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
	echo ""
}

yesno()
{
	MESSAGE="$1"
	while true; do
		echo "$MESSAGE <yes|no>"
  		read YESNO
  		case $YESNO in
  		  y | yes | Y | Yes | YES ) return 0 ;;
  		  n | no | N | No | NO )  return 1 ;;
  		  * ) echo "Please enter yes or no." ;;
  		esac
	done  
}

cleanup()
{
	rm -Rf "$TMPDIR"
}


 # Added 10/14/2013 This isn't going to work matt.. you are passing everything
if [[ -z "$1" ]] ; then
	syntax
	exit 1
fi

while getopts ahmrpu opt ;do
        case $opt in
                m) FORMAT="manpage" ;;
                p) FORMAT="pdf" ;;
                \?) echo "Unknown option" ; syntax ;;
        esac
done
shift $(($OPTIND - 1))

setup

# Replaced "$@" with $TARGET so we could specify the directory
for ITEM in $@ ;do
	if [[ -d "$ITEM" ]] ;then
		for FILE in $(find $ITEM -name '*.ad') ;do
			case "$FORMAT" in
				pdf) makepdf "$FILE" ;;
				manpage) makeman "$FILE" ;;
			esac
		done
	else
		case "$FORMAT" in
			pdf) makepdf "$ITEM" ;;
			manpage) makeman "$ITEM" ;;
		esac
	fi 

done

trap EXIT cleanup
