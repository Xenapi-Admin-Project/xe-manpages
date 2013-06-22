#!/bin/bash

# Converts source documents to pdf, man or html
# Created by Grant McWilliams
# Version 0.1
# October 22, 2012

setup()
{
	DOCDIR="$HOME/Projects/xe-manpages"
	SRCDOCDIR="$DOCDIR/docs/source/asciidoc"
	MANDOCDIR="$DOCDIR/docs/manpage"
	PDFDOCDIR="$DOCDIR/docs/pdf"
	BINDIR="$DOCDIR/bin"
	TMPDIR=$(mktemp -d)
	PROGNAME=$(basename $0)
	
	for DIR in "$SRCDOCDIR" "$MANDOCDIR" "$PDFDOCDIR" ; do
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

syntax()
{
	echo ""
	echo "$PROGNAME [options] <asciidoc file>"
	echo "options:"
	echo "-m   make manpage document type"
	echo "-p   make pdf document type"
	echo ""
}

makeman()
{	
	FILE="$1"
	echo "Converting $FILE to manpage"
	cp -f "$FILE" "$TMPDIR"
	TMPFILE=$(basename "$FILE") 
	a2x --doctype manpage -f manpage "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
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

setup
if [[ -z "$1" ]] ; then
	syntax
	exit 1
fi


while getopts ahmpu opt ;do
        case $opt in
                m) FORMAT="manpage" ;;
                p) FORMAT="pdf" ;;
                \?) echo "Unknown option" ; syntax ;;
        esac
done
shift $(($OPTIND - 1))

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

cleanup
