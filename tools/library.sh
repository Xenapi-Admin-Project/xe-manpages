#give names to ansi sequences
setcolors()
{
	black='\e[30;47m'
	white='\e[37;47m'
    red='\e[0;31m'
    blue='\e[0;34m'
    cyan='\e[0;36m'
    off='\e[0m'
}

#color echo
cecho ()                     
{
	MSG="${1}"       
	if [ -z $2 ] ;then
		color="off"
	else
		eval color=\$$2
	fi     
  	echo -ne "${color}"
  	echo -ne "$MSG"
  	echo -ne "${off}"                      
}

printspaces()
{
	# arg 1 - the longest item in the column (integer)
	# arg 2 - the length of the item ie. ${#VAR} (integer)
	COLUMN="$1"
	ITEM="$2"
	
	if [[ "$CSV" = "yes" ]] ;then
		echo -ne ","
	else
		printf "%*s" "$(( $COLUMN + $MINSPACE - $ITEM ))"
	fi 
}

#get width of columns
getcolwidth()
{
	#get longest item in array
	array=( "$@" )
	i=0
	LONGEST="0"
	IFS=$'\n'
	for ITEM in ${array[@]} ;do
		if [[ "${#ITEM}" -gt "$LONGEST" ]] ;then
			LONGEST="${#ITEM}"
		fi
	done
	echo "$LONGEST"
}

printheadings()
{
	# Print column headings
	for i in $(seq 0 $(( ${#TITLES[@]} - 1 )) ) ;do
		cecho "${TITLES[$i]}" off
		printspaces "${COLLONGEST[$i]}"  "${#TITLES[$i]}" 	
	done
	echo ""
}

getunit()
{
 	SIZE="$1"
        for UNIT in K M G
        do
                SIZE=$(echo "scale=0; $SIZE / 1024" | bc)
                if [[ $SIZE -lt 1024 ]]
                then
                        SIZE=${SIZE}${UNIT}
                        break
                fi
        done
	echo "$SIZE"
}

yesno()
{
	# a simple yesno function 
	# usage:  if yesno "Do you like dogs?" ;then ...

	echo -n "$1 <y|n>: "
	read ANS
	while true ;do
		case $ANS in
			[yY] | [yY][Ee][Ss] ) return 0 ;;
			[nN] | [n|N][O|o] )   return 1 ;;
			*) echo "Invalid input"        ;;
		esac
	done
}
