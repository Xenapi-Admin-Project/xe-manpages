# Version 3.0

#give names to ansi sequences
setcolors()
{
	black='\e[30;47m'
	white='\e[37;47m'
    red='\e[0;31m'
    RED='\e[1;31m'
    blue='\e[0;34m'
    BLUE='\e[1;34m'
    cyan='\e[0;36m'
    CYAN='\e[1;36m'
    off='\e[0m'
}

#color echo
cecho ()                     
{
	MSG="${1}"  
	if [[ "$CSV" = "yes" ]] ;then 
	  	echo -ne "$MSG"
	else    
		if [ -z $2 ] ;then
			color="off"
		else
			eval color=\$$2
		fi     
		echo -ne "${color}"
		echo -ne "$MSG"
		echo -ne "${off}"
	fi                      
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

# Print column headings
printheadings()
{
	TITLEMAX=$(( ${#TITLES[@]} - 1 ))
	for i in $(seq 0 "$TITLEMAX" ) ;do
		cecho "${TITLES[$i]}" off
		if [[ ! "$i" -eq "$TITLEMAX" ]] ;then
			printspaces "${COLLONGEST[$i]}"  "${#TITLES[$i]}" 	
		fi
	done
	echo ""
}

# Check if argument is a number
isnumber()
{
	case "$1" in
		''|*[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac	
}	

# Check if argument is a UUID
isuuid()
{
	if [[ "$1" =~ "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" ]] ; then
		return 0
	else
		return 1
	fi	
}

# Convert number to human readable size
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

# Simple yesno function returns 0 or 1
yesno()
{
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

# Sort parallel arrays. Sort order defined by first array. Pass array name only eg sort_arrays array1
sort_arrays()
{
	IFS=$'\n'
	
	# Get all arrays and assign the values to local variables
	# Assign variable names to TMPARR and TMPARG before you do any real value assignements
	for i in $(seq 1 ${#@}) ;do
		local TMPARR="ARRAY${i}"										# $TMPARR = 'ARRAY1' literally
		eval local TMPARG="\$${i}"										# $TMPARG = '$ar1' literally, $ar1 is $1 
		eval local ${TMPARR}=\( \"\$\{$TMPARG\[@\]\}\" \)				# ARRAY1 = $ar1
	done

	# Sort ARRAY1 and do identical operations for the other arrays
	for (( MAX=${#ARRAY1[@]} - 1 ; MAX > 0 ; MAX-- )) ;do				# Bubble sort 
		for (( i = 0 ; i < MAX ; i++ )) ;do
			local j=$((i + 1))
			if expr "${ARRAY1[$i]}" \> "${ARRAY1[$j]}" >/dev/null ;then # expr sorts ARRAY1 items properly
				for (( k=${#@} ; k > 0 ; k-- )) ;do						# if [[ $1 > $2 ]] put upper case first
					local EARG="ARRAY${k}"								# $EARG = 'ARRAY1' or 'ARRAY2' literally
					eval local t=\"\$\{$EARG\[$i\]\}\"					# t = $ARRAY1[1] etc
					eval $EARG\[$i\]=\"\$\{$EARG\[$j\]\}\"				# ARRAY1[1] = ${ARRAY1[2]} 
					eval $EARG\[$j\]=\"$t\"								# ARRAY1[2] = $t - old value of ARRAY1[1]
				done
            fi
        done
    done

	# Copy data from local arrays back to original arrays
	for i in $(seq 1 ${#@}) ;do											# for 1 in # of arguments
		local TMPARR="ARRAY${i}"											# TMPARR = 'ARRAY1' literally
		eval local TMPARG="\$${i}"										# $TMPARG = '$ar1' literally, $ar1 is $1 
		eval ${TMPARG}=\( \"\$\{$TMPARR\[\@\]\}\" \)					# ar1[@] = $ARRAY1[@]
	done
}	

# Fast sort arrays using sort command and a temporary file
fsort_arrays()
{
	# Copy argument arrays to internal arrays
	for i in $(seq 1 ${#@}) ;do
		local TMPARR="ARRAY${i}"										
		eval local TMPARG="\$${i}"										
		eval local ${TMPARR}=\( \"\$\{$TMPARG\[@\]\}\" \)				
	done

	# Sort using the sort command
	for i in $(seq 0 $(( ${#ARRAY1[@]} - 1 )) ) ;do
		for j in $(seq 1 ${#@}) ;do
			local COLUMNTMP="ARRAY${j}"
			eval local COLUMN=\"\$\{$COLUMNTMP\[\$\i\]\}\"
			eval echo -en "${COLUMN}@#@"
		done
		echo "" 
	done | sort > "$TMPDIR/tmpllist.txt"
	
	# Copy internal arrays back to global arrays
	for i in $(seq 1 $(( ${#@} )) ) ;do																			
		eval local TMPARG="\$${i}"												
		eval ${TMPARG}=\( $(awk -F "@#@" "{total = \$${i}} {print total}" "$TMPDIR/tmpllist.txt") \)
	done
}

# Set ${XE} variable to include server, username and password 
getpoolcreds()
{
	# Check to see if there's a local config file 
	# File format  POOLMASTER="hostname" \n PORT="port" \n USERNAME="username" \n PASSWORD="password"
	if [[ "$REMOTE" = "yes" ]] ;then
		if [[ -d "$SCRIPTDIR/.XECONFIGS" ]] ;then
			PERMS=$(stat -c '%a' "$SCRIPTDIR/.XECONFIGS")
			if [[ "$PERMS" =~ "[5-7]00" ]] ;then
				select POOLHOST in $(awk -F= '/POOLMASTER/{print $2}' $SCRIPTDIR/.XECONFIG/*.cfg | sed 's/\"//g') ;do
					XECONF=$(grep "$POOLHOST" $SCRIPTDIR/.XECONFIG/*.cfg | awk -F: '{print $1}')
					source "$XECONF"
					break ;
				done
			else
				cecho "Warning: " red 
				echo "Permissions allow other users to read $SCRIPTDIR/.xetoolsconfig" 
				echo "Please remove read permissions for other users and re-run program"
				exit
			fi
		fi
		if [[ -z "$POOLMASTER" ]] ;then
			echo "Enter the remote poolmaster ip or hostname"
			read -s POOLMASTER
		fi
		if [[ -z "$PORT" ]] ;then
			echo "Enter the remote poolmaster port number [default 443]"
			read -s PORT
		fi
		if [[ -z "$PASSWORD" ]] ;then
			echo "Enter the remote poolmaster admin password"
			read -s PASSWORD
		fi
		export XE_EXTRA_ARGS="server=${POOLMASTER},port=${PORT},username=${USERNAME},password=${PASSWORD}"
	fi
	
}	

# Show a select menu by passing multiple arrays, return UUID. Only pass ONE array holding UUID
show_arraymenu()
{
	# Copy argument arrays to internal arrays
	for i in $(seq 1 ${#@}) ;do
		local TMPARR="ARRAY${i}"										
		eval local TMPARG="\$${i}"										
		eval local ${TMPARR}=\( \"\$\{$TMPARG\[@\]\}\" \)				
	done

	# get longest item in each array
	for i in $(seq 1 ${#@}) ;do											
		local COLARR="ARRAY${i}"																				
		local COLLONG[$i]=$(eval getcolwidth \$\{$COLARR\[@\]\} )
	done

	for i in $(seq 0 $(( ${#ARRAY1[@]} - 1 )) ) ;do
		for j in $(seq 1 ${#@}) ;do
			local COLUMNTMP="ARRAY${j}"
			eval COLUMN=\$\{$COLUMNTMP\[\$\i\]\}
			eval cecho "$COLUMN" off
			printspaces "${COLLONG[$j]}" "${#COLUMN}"
		done
		echo "" 
	done | sort > "$TMPDIR/tmpllist.txt"

	OLDIFS="$IFS" ; IFS=$'\n'
	PS3="Please Choose: " ; echo ""
	select LINE in $(cat "$TMPDIR/tmpllist.txt")
	do
		echo "$LINE" | egrep -o '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'
		break ;
	done
}







