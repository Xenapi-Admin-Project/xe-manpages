#!/bin/bash
set -x
DIR=$1

# create temp dirs!

setup(){
	 
	TEMPFILE=/tmp/manpagemaker/tmpfile.tmp
	TEMPDIR=/tmp/manpagemaker/
	TEMPMANDIR=/tmp/manpagemaker/manpages/
	SERVERIP="root@cloudmatt.ssh22.net"
	PORT="10551"
}

cleanup(){

	rm -rf "$TEMPDIR"

}

movepages(){

	cp -R "${TEMPMANDIR}." "${DIR}"

}

makedirs(){

	if ! [ -e "$TEMPDIR" ] ;then
	mkdir "$TEMPDIR" ; mkdir "$TEMPMANDIR"	
	fi

}

makepages(){

ssh -p "$PORT" -S /tmp/manpagemaker/ssh.connect -MfN "$SERVERIP"
for xe in ${XECOMMANDS[@]} ;do
	command=${xe#*-} ; command=${command%.*}
	ssh -p "$PORT" -S /tmp/manpagemaker/ssh.connect "$SERVERIP" 'bash -s' < manpagemaker.sh "$command" > "${TEMPMANDIR}${xe}"
done

}

findempty(){

ls -l "$DIR" | tail -n +2 |  sed 's/\s\+/ /g' | cut -d" " -f5,9 > "$TEMPFILE"

i=0
while read line ;do
	XECOMMAND=$(echo $line | cut -d" " -f2)
	PWDXECOMMAND="${DIR}${XECOMMAND}"
	
	if ! [ -s "$PWDXECOMMAND" ]; then
		XECOMMANDS[$i]=$XECOMMAND
		(( i++ ))
	fi
	
done < "$TEMPFILE"

}


setup
makedirs
findempty
makepages
movepages
cleanup



		
