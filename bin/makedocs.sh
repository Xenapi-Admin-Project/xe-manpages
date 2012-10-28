#!/bin/bash

# Converts source documents to pdf, man or html
# Created by Grant McWilliams
# Version 0.1
# October 22, 2012

setup()
{
	DOCDIR="$HOME/xcpdocs"
	SRCDOCDIR="$DOCDIR/trunk/docs/source/asciidoc"
	MANDOCDIR="$DOCDIR/trunk/docs/manpage"
	PDFDOCDIR="$DOCDIR/trunk/docs/pdf"
	HTMLDOCDIR="$DOCDIR/trunk/docs/html"
	BINDIR="$DOCDIR/trunk/bin"
	TMPDIR=$(mktemp -d)
	PROGNAME=$(basename $0)
	UPDATE="no"
	PROGLOG="${TMPDIR}/progress.log"
	
	if [[ -e "$PROGLOG" ]] ;then
		rm -f "$PROGLOG"
	fi
	
	if [[ ! -d "$DOCDIR" ]] ;then
		echo "Can't find $DOCDIR. Create a symbolic link to your xcpdocs directory"
		echo "eg. ln -s /home/bob/Projects/xcpdocs ~/xcpdocs"
		exit 1
	fi
	
	for DIR in "$SRCDOCDIR" "$MANDOCDIR" "$PDFDOCDIR" ; do
		if [[ ! -d "$DIR" ]] ;then
			echo "$DIR doesn't exist - maybe subversion isn't set up"
			exit 1
		fi
	done

	if ! which a2x &> /dev/null ; then
		echo "a2x command not installed - exiting"
		exit 1
	fi

	if ! which svn &> /dev/null ; then
		echo "SVN command not installed - $PROGNAME will work but won't be able to documents in subversion"
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
	echo "-a   make all document types"
	echo "-h   make html document type"
	echo "-m   make manpage document type"
	echo "-p   make pdf document type"
	echo "-u   update subversion"
	echo ""
}

makeall()
{
	FILE="$1"
	makeman "$FILE"
	makehtml "$FILE"
	makepdf "$FILE"
}

makeman()
{	
	FILE="$1"
	echo "Converting $FILE to manpage"
	cp -f "$FILE" "$TMPDIR"
	TMPFILE=$(basename "$FILE")
	a2x -f manpage "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
	echo "$TMPFILE" >> "$PROGLOG"
	echo ""
}

makehtml()
{	
	FILE="$1"
	echo "Converting $FILE to html"
	TMPFILE=$(basename "$FILE")
	a2x -f html "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
	echo "$TMPFILE" >> "$PROGLOG"
	echo ""
}

makepdf()
{	
	FILE="$1"
	echo "Converting $FILE to pdf"
	TMPFILE=$(basename "$FILE")
	a2x -f pdf "${TMPDIR}/${TMPFILE}" -D "${MANDOCDIR}/"
	echo "$TMPFILE" >> "$PROGLOG"
	echo ""
}

updatedocs()
{
	DOCARRAY=( $(cat "$1" | sed ':a;N;$!ba;s/\n/,/g' ) )
	cat "$1"
	read
	echo ${DOCARRAY[@]}
	read
	cd "$DOCDIR" ; svn commit -m "Created docs for ${DOCARRAY[@]}"
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
                a) FORMAT="all" ;;
                h) FORMAT="html" ;;
                m) FORMAT="manpage" ;;
                p) FORMAT="pdf" ;;
				u) UPDATE="yes" ;;
                \?) echo "Unknown option" ; syntax ;;
        esac
done
shift $(($OPTIND - 1))

for ITEM in $@ ;do
	if [[ -d "$ITEM" ]] ;then
		for FILE in $(find $ITEM -name '*.ad') ;do
			case "$FORMAT" in
				html) makehtml "$FILE" ;;
				pdf) makepdf "$FILE" ;;
				manpage) makeman "$FILE" ;;
				all) makeall "$FILE" ;;
			esac
		done
	else
		case "$FORMAT" in
			html) makehtml "$ITEM" ;;
			pdf) makepdf "$ITEM" ;;
			manpage) makeman "$ITEM" ;;
			all) makeall "$ITEM" ;;
		esac
	fi 

done

if [[ "$UPDATE" = "yes" ]] ;then
	updatedocs "$PROGLOG"
fi

cleanup







