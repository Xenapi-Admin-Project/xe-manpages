#!/bin/bash

ADOCPATH="../docs/source/asciidoc"

echo "This command is destructive - edit and remove the following line if you know for sure you should use it"
exit

for SUBCOMMAND in $(ssh root@testcloud1 "xe help --all --minimal | sed 's/,/\n/g' | sed -e 's/^[ \t]*//'" | sed '/^$/d')
do
        OBJECT=$(echo $SUBCOMMAND | awk -F\- '{print $1}' | tr '[:lower:]' '[:upper:]' )_COMMANDS
        if [ -L "${ADOCPATH}/RELEASE/xe-${SUBCOMMAND}.ad" ] ;then
                git rm -f "${ADOCPATH}/RELEASE/xe-${SUBCOMMAND}.ad"         
                git mv "${ADOCPATH}/${OBJECT}/xe-${SUBCOMMAND}.ad" "${ADOCPATH}/RELEASE/"
        else    
                if [ ! -d "${ADOCPATH}/${OBJECT}" ] ;then
                        mkdir -p "${ADOCPATH}/${OBJECT}"
                fi              
                touch "${ADOCPATH}/${OBJECT}/xe-${SUBCOMMAND}.ad"             
                git add "${ADOCPATH}/${OBJECT}/xe-${SUBCOMMAND}.ad"
                git commit -m "Adds xe-${SUBCOMMAND}.ad"
        fi
read blank

done

