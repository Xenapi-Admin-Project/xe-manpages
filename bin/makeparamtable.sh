#!/bin/bash

echo "This commmand is destructive - delete the following line if you know for sure that you should use it"
#exit

SEP="@#@"
TMPTABLE="/tmp/tmp-paramtable.txt"
PARAMTABLE="$HOME/bin/xe-paramtable.txt"

if [[ ! -e "$PARAMTABLE" ]] ;then
	if [[ ! -d ${PARAMTABLE%/*} ]] ; then
		mkdir -p "${PARAMTABLE%/*}"
	fi
fi

get_all_params()
{
	echo "Mapping all possible command parameters"
	for XE_COMMAND in $(xe help --all --minimal | sed 's/,/\n/g') ;do
		OBJECT=${XE_COMMAND%%-*}
		OBJTYPE=${XE_COMMAND#*-}
		OBJECTUPPER=$(echo $OBJECT | tr 'a-z' 'A-Z')
		
		IFS=","
		PARAMS=$(xe help "$XE_COMMAND" | grep "reqd params" | sed -e 's/^.*reqd params[ ]*:[ ]//')
		for PARAM in $PARAMS ;	do
			CLEANPARAM=$(echo $PARAM | sed -e 's/^[ \t]*//' | sed -e 's/:$//')
			echo "${XE_COMMAND}${SEP}${CLEANPARAM}${SEP}"
		done
		PARAMS=$(xe help "$XE_COMMAND" | grep "optional params" | sed -e 's/^.*optional params[ ]:[ ]//')
		for PARAM in $PARAMS ;	do
			CLEANPARAM=$(echo $PARAM | sed -e 's/^[ \t]*//' | sed -e 's/:$//')
			echo "${XE_COMMAND}${SEP}${CLEANPARAM}${SEP}" 
		done
	done | sort -u > "$TMPTABLE"
}

get_current_params()
{
	echo "Mapping current commmand parameters"
	IFS=$'\n'
	for PAGE in $(find /root/Project/xe-manpages/docs/source/ -iname *.ad) ;do 
		VAR=${PAGE##*/}; VAR=${VAR%.*}; XE_COMMAND=${VAR#*-}		
		for PARAM in $(cat "$PAGE" | grep '\*::') ; do
			CLEANPARAM=$(echo $PARAM | sed 's/\:\://g' | sed 's/\*//g' | sed 's/[ \t]*$//g'| sed -e 's/^[ \t]*//' )
			VALUE=$(grep -A1 "\*$CLEANPARAM\*\:\:" "$PAGE" | tail -n1 | sed 's/\:\:[ \t]*$//g'| sed -e 's/^[ \t]*//') 
			if [[ -z "$VALUE" ]] ;then
				continue
			else
				DESC=$(grep "${XE_COMMAND}${SEP}${CLEANPARAM}${SEP}" $TMPTABLE | awk -F\"${SEP}\" '{print $3}')
				if [[ -z "$DESC" ]] ;then
					grep -v "${XE_COMMAND}${SEP}${CLEANPARAM}${SEP}" "$TMPTABLE" > /tmp/tmpfile.txt
					echo    "${XE_COMMAND}${SEP}${CLEANPARAM}${SEP}${VALUE}" >> /tmp/tmpfile.txt
					sort /tmp/tmpfile.txt > "$TMPTABLE"
					rm -f /tmp/tmpfile.txt
				fi
			fi
		done
	done 
}

yesno()
{
	echo -n "$1? <y|n> "
	read ANS
	while true ;do
		case $ANS in
			[yY] | [yY][Ee][Ss] ) return 0 ;;
			[nN] | [n|N][O|o] )   return 1 ;;
			*) echo "Invalid input"        ;;
		esac
	done
}

get_all_params
get_current_params

if yesno "Overwrite $PARAMTABLE" ;then
	echo "Overwriting $PARAMTABLE" ; cp -f "$TMPTABLE" "$PARAMTABLE" 
else
	exit 0
fi


