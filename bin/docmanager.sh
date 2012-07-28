#!/bin/bash

# Creates various output formats of Docbook xml source files and uploads them to a fileserver
# Created by Grant McWilliams
# Version 0.1
# July 17th 2012

#directories
DOCDIR="$HOME/xcpdocs"
BINDIR="$DOCDIR/bin"
SRCDOCDIR="$DOCDIR/docs/source"
PDFDOCDIR="$DOCDIR/docs/pdf"
HTMLDOCDIR="$DOCDIR/docs/html"
EPUBDOCDIR="$DOCDIR/docs/epub"
MANDOCDIR="$DOCDIR/docs/manpage"
TMPDIR="/tmp/$(basename $0)"
UPLOADTYPE="rsync"  # rsync, scp, git, svn
DOCSERVER="cloud.acs.edcc.edu"
DOCSERVERPORT="10150"
DOCADMINUSER="root"
DOCUSER="grant"
PNAME=$(basename $0)

#params
MKPDF="0"
MKEPUB="0"
MKMAN="0"
MKHTML="0"

setup()
{
	for DIR in "$TMPDIR" "$DOCDIR" "$BINDIR" "$PDFDOCDIR" "$HTMLDOCDIR" "$EPUBDOCDIR" "$MANDOCDIR" "$SRCDOCDIR"
	do
		if [ ! -d "$DIR" ] ;then
			mkdir -p "$DIR"
		fi
	done
	if [ ! -L "$BINDIR/${PNAME%.*}" ] ; then
		ln -s "$BINDIR/$PNAME" "$BINDIR/${PNAME%.*}"
	fi
	if [ -z $DOCUSER ] ; then
		echo "DOCUSER needs to be set at the top of this script to enable uploading of document files"
	fi
	if ! which rsync &> /dev/null ; then
		echo "RSYNC command not installed - makedocs will work but won't be able to rsync documents"
	fi

	if ! which scp &> /dev/null ; then
		echo "SCP command not installed - makedocs will work but won't be able to copy documents to server"
	fi
	if ! which fop &> /dev/null ; then
		echo "The fop command not installed - makedocs will not be able to create pdf documents"
	fi
	if ! which xsltproc &> /dev/null ; then
		echo "The xsltproc command not installed - makedocs will not be able to process documents"
		exit 1
	fi
}

syntax()
{
	echo ""
	echo "$PNAME [options]"
	echo "Options:"
	echo "-a   make all document types"
	echo "-e   make ePUB document type"
	echo "-h   make html document type"
	echo "-m   make manpage document type"
	echo "-p   make pdf document type"
	echo "-c   clean documents, takes two arguments - local or remote"
	echo "-t   specify upload network protocol - rsync, scp"
	echo "-u   upload documents. Note: do not clean and upload in the same operation"
	echo ""
	exit 1
}

makeman()
{	
	FILE="$1"
	echo "Outputting manpage version of $FILE"
	xsltproc -o ${MANDOCDIR}/ --nonet --param man.charmap.use.subnet "0" --param make.year.ranges "1" --param make.single.year.ranges "1" http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl "$FILE"
}

makehtml()
{	
	FILE="$1"
	echo "Outputting html version of $FILE "
	xsltproc -o ${HTMLDOCDIR}/${FILE%.*}.html --nonet --param man.charmap.use.subnet "0" --param make.year.ranges "1" --param make.single.year.ranges "1" /usr/share/xml/docbook/stylesheet/docbook-xsl/html/docbook.xsl "$FILE"
}

makeepub()
{	
	FILE="$1"
	if [ ! -d ${EPUBDOCDIR}/${FILE%.*} ] ;then
		mkdir -p ${EPUBDOCDIR}/${FILE%.*}
	fi
	echo "Outputting epub version of $FILE"
	xsltproc -o ${EPUBDOCDIR}/${FILE%.*}/  --nonet --param man.charmap.use.subnet "0" --param make.year.ranges "1" --param make.single.year.ranges "1" /usr/share/xml/docbook/stylesheet/docbook-xsl/epub/docbook.xsl "$FILE"
}

makepdf()
{	
	FILE="$1"
	echo "Outputting PDF version of $FILE"
	xsltproc -o $TMPDIR/intermediate-fo-file.fo /usr/share/xml/docbook/stylesheet/nwalsh/fo/docbook.xsl "$FILE"
	fop -pdf ${PDFDOCDIR}/${FILE%.*}.pdf -fo ${TMPDIR}/intermediate-fo-file.fo 
}

uploaddocs()
{
	if [ -z "$DOCUSER" ] ; then
		echo "DOCUSER needs to be set at the top of this script to enable uploading of document files"
		return 1
	fi
	case "$UPLOADTYPE" in
		rsync)
			rsync -av --progress --rsh="ssh -p ${DOCSERVERPORT}" ${DOCDIR}/docs ${DOCADMINUSER}@${DOCSERVER}:~/xcpdocs/${DOCUSER}/
		;;
		scp)
			scp -r -P ${DOCSERVERPORT} ${DOCDIR}/docs ${DOCADMINUSER}@${DOCSERVER}:~/xcpdocs/${DOCUSER}/ 
		;;
		svn)
			echo svndocs
		;;
		git)
			echo gitdocs
		;;
	esac
}

cleandocs()
{
	DOCLOC="$1"
	echo ""
	if yesno "Do you really want to delete all $DOCLOC documents for the user $DOCUSER?"
	then
		case $DOCLOC in
			local)
				for DIR in "$PDFDOCDIR" "$HTMLDOCDIR" "$EPUBDOCDIR" "$MANDOCDIR" 
				do
					rm -Rf "${DIR}"
				done	
			;;
			remote)
				if [ -z $DOCUSER ] ; then
					echo "DOCUSER needs to be set at the top of this script to enable uploading of document files"
					return 1
				fi
				echo ""
				echo "Deleting $DOCLOC documents currently works with ssh/rsync servers only"
				ssh -p ${DOCSERVERPORT} ${DOCADMINUSER}@${DOCSERVER} "rm -Rf /${DOCADMINUSER}/xcpdocs/${DOCUSER}/docs/*"
			;;
		esac
	fi
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

#MAIN 

if [ -z $1 ] ; then
	syntax
fi

while getopts aehmpuc:t: opt
do
        case $opt in
                a) MKPDF="1" MKEPUB="1" MKMAN="1" MKHTML="1" ;;
                e) MKEPUB="1" ;;
                h) MKHTML="1" ;;
                m) MKMAN="1" ;;
                p) MKPDF="1" ;;
		u) uploaddocs ;;
                c) cleandocs "$OPTARG" ;;
		t) UPLOADTYPE="$OPTARG" ;;
                \?) echo "Unknown option" ; syntax ;;
        esac
done
shift $(($OPTIND - 1))

setup
cd ${DOCDIR}/docs/source/
for FILE in *.xml
do
	if [ $FILE = example_manpage.xml ] ;then
		continue
	fi
	if [ "$MKMAN" -eq 1 ] ; then 
		makeman "$FILE"
	fi
	if [ "$MKHTML" -eq 1 ] ; then 
		makehtml "$FILE"
	fi
	if [ "$MKEPUB" -eq 1 ] ; then
		makeepub "$FILE"
	fi
	if [ "$MKPDF" -eq 1 ] ; then
		makepdf "$FILE"
	fi
done

cleanup







