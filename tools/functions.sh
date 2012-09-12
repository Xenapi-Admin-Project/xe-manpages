

sort_templates()
{   
    # Sorts TMPLNAMES using a bubble sort
    # Reorders TMPLUUIDS to match
    # Had to use expr becuase using bash sort (>) put capitols before lowercase
    # expr is much slower than [[ $var1 > $var2 ]] but is the only way to get both lower and upper case to 
    # sort properly without using tr which was twice as slow as expr
	IFS=$'\n'
	local MAX=$((${#TMPLNAMES[@]} - 1))
	
    while ((MAX > 0)) ;do
       	local i=0 
        while ((i < MAX)) ;do
			local j=$((i + 1))
			if expr "${TMPLNAMES[$i]}" \< "${TMPLNAMES[$j]}" >/dev/null
			then
                local t=${TMPLNAMES[$i]}
                local u=${TMPLUUIDS[$i]}
                TMPLNAMES[$i]=${TMPLNAMES[$j]}
                TMPLUUIDS[$i]=${TMPLUUIDS[$j]}
                TMPLNAMES[$j]=$t
                TMPLUUIDS[$j]=$u
            fi
            ((i++))
        done
        ((MAX--))
    done
}



