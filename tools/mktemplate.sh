#!/bin/bash

if_yes()
{
    MSG=$1
    echo "$MSG y|n"
    read ANS
    case $ANS in
        y|Y|yes|Yes|YES)
            return 0
        ;;
        n|N|no|No|NO)
            return 1
        ;;
    esac
}    

get_template()
{
    OLD_IFS=${IFS}
    IFS=$'\n'
    PS3="Please Choose: "
    select TPL in $(xe template-list params=name-label --minimal | sed 's/,/\n/g' | sort) Quit
    do  
        if [ $TPL = Quit ] ;then
            exit 1
        fi
        TPLUUID=$(xe template-list name-label=$TPL --minimal)
        break; 
    done
    IFS=${OLD_IFS}
}

get_arches()
{
    PS3="Please Choose: "
    select ARCH in "32-bit" "64-bit" "Both" Quit
    do  
        case $ARCH in
            "32-bit")
                ARCHES=("32-bit")
                break 2;
            ;;
            "64-bit")
                ARCHES=("64-bit")
                break 2;
            ;;
            "Both")
                ARCHES=("32-bit" "64-bit")
                break 2; 
            ;;
        esac
    done
}

get_name()
{
    echo "Please enter Distribution name ie. CentOS 5.5"
    read NAME
}

get_params()
{
    echo ""
    PARAMETERS=("other-config:install-methods=http,ftp,nfs" "other-config:default_template=true")
}

get_name_label()
{
    UUID=$1
    NAMELABEL=$(xe template-list uuid=${UUID} params=name-label --minimal)
}

show_template()
{
    UUID=$1
    xe template-param-list uuid=$UUID
    echo "---------------------------------------------------"
    if ! if_yes "Do you want to keep this template? " 
    then
        get_name_label "$UUID"
        echo "Uninstalling template $NAMELABEL"
        xe template-param-set other-config:default_template=false uuid="$UUID"
        xe template-uninstall template-uuid="$UUID" force=true
    fi
}    
    
create_template()
{
    get_template
    get_name
    get_arches
    get_params

    for ARCH in ${ARCHES[@]} ; do
        echo "Attempting $NAME ($ARCH)"
        if [[ -n $(xe template-list name-label="$NAME ($ARCH)" params=uuid --minimal) ]] ; then
            echo "$NAME ($ARCH)" already exists, Skipping
        else
            NEWUUID=$(xe vm-clone uuid=$TPLUUID new-name-label="$NAME ($ARCH)")
            xe template-param-set uuid=$NEWUUID ${PARAMETERS[@]}
            if if_yes "Would you like to show the template parameters? "
            then
                show_template $NEWUUID 
            fi
        fi
    done   
}    

create_template


