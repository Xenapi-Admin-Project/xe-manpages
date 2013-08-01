#!/bin/bash
# Installer for needed asciidoc packages and cloning XenApiAdmin Git
# https://github.com/Xenapi-Admin-Project/xe-manpages
# www.xenapiadmin.com
# Last modified: 07/11/2013
# Author: Adam Sparks <asparks914 at gmail.com>
echo ""
echo -e "\033[33mPlease select a Distro: \033[0m"
echo ""
select option in Debian/Ubuntu/Mint RHEL/CentOs/Fedora Quit
do
  case $option in

# Debian systems
    Debian/Ubuntu/Mint)
      echo ""
      echo -e "\033[33m+++++Debian based install+++++ \033[0m"
      sleep 2
      echo ""
      echo -e "\033[33m++++++Updating Databases++++++ \033[0m"
      echo ""
            sudo apt-get update
      
      sleep 2

      echo ""
      echo -e "\033[33m+++++Installing Pacakges++++++ \033[0m"
      sleep 2
      echo ""
	    sudo apt-get -y install docbook docbook-xsl \
	    docbook-xsl-doc-pdf docbook-xsl-doc-html libservlet2.4-java docbook2odf \
	    docbook2x xsltproc asciidoc git
      break;;

# Fedora systems
      RHEL/CentOs/Fedora)
       echo ""
       echo -e "\033[33m+++++RHEL based install+++++ \033[0m"
       sleep 2
       echo ""
       echo -e "\033[33m+++++Installing Packages+++++ \033[0m"
       sleep 2
       echo ""
            sudo yum install -y docbook-dtds docbook-simple docbook-utils-pdf \
            docbook-style-dsssl docbook2X docbook-utils docbook-style-xsl \
            xsltproc asciidoc git
       break;;

      Quit)
       echo -e "\033[33m Quit \033[0m"
       exit
       break;;
    esac

done

sleep 2
echo ""
echo -e "\033[33m+++++Creating projects directory+++++\033[0m"
mkdir ~/projects
cd ~/projects
sleep 2
echo ""
echo -e "\033[33m+++++Cloning project+++++ \033[0m"
echo ""
sleep 1
git clone https://github.com/Xenapi-Admin-Project/xe-manpages.git
cd ~

sleep 1
echo ""
echo -e "\033[33mWould you like to setup your git config? (You can skip this if you git setup already.): \033[0m"
select option in Yes No
do
  case $option in
    Yes)
      echo ""
      echo -e "\033[33mYour full name please? (This will be seen when making commits on GitHub): \033[0m"
      read NAME
      git config --global user.name "$NAME"
      echo ""
      echo -e "\033[33mYour email address?: \033[0m"
      read EMAIL
      git config --global user.email $EMAIL
      git config --global credential.helper cache
      git config --global credential.helper 'cache --timeout 3600'
      echo -e "\033[33mDone. \033[0m"
    break;;

    No)
      echo -e "\033[33mDone. \033[0m"  
    break;;
  esac
done

echo ""
echo ""
echo -e "\033[33mYour .gitconfig is now setup in $HOME/.gitconfig and"
echo -e "the project was cloned to $HOME/projects directory."
echo -e "Please see our website at xenapiadmin.com for more details. \033[0m"
echo ""
