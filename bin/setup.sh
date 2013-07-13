#!/bin/bash
# Installer for needed asciidoc packages and cloning our git
# Per his holiness's wishes Fedora AND Debian/Ubuntu now included
echo ""
PS3="Please select a Distro: "
select option in Debian/Ubuntu/Mint RHEL/CentOs/Fedora Quit
do
  case $option in

# Debian systems
    Debian/Ubuntu/Mint)
      echo "Debian based install........" 
            sudo apt-get -y install docbook docbook-xsl docbook-xsl-doc-pdf \
            docbook-xsl-doc-html libservlet2.4-java docbook2odf docbook2x \
            xsltproc asciidoc git

      break;;
# Fedora systems
      RHEL/CentOs/Fedora)
        echo "RHEL based install......."
            sudo yum install -y docbook-dtds docbook-simple docbook-utils-pdf \
            docbook-style-dsssl docbook2X docbook-utils docbook-style-xsl \
            xsltproc asciidoc git
        break;;

      Quit)
        echo "Quit"
        break;;
    esac

done

echo ""
echo "Creating projects directory.........................."
mkdir ~/projects
cd projects
echo ""
echo "Cloning project....................."
git clone https://github.com/Xenapi-Admin-Project/xe-manpages.git
cd ~

echo ""
PS3="Would you like to setup your git config? (You can skip this if you git setup already.): "
select option in Yes No
do
  case $option in
    Yes)
      echo ""
      echo "Your full name please? (This will be seen when making commits on GitHub): "
      read NAME
      git config --global user.name "$NAME"
      echo ""
      echo "Your email address?: "
      read EMAIL
      git config --global user.email $EMAIL
      git config --global credential.helper cache
      git config --global credential.helper 'cache --timeout 3600'
      echo "Done"
    break;;

    No)
      echo "Done"  
    break;;
  esac
done

echo ""
echo ""
echo "All done. The project has been cloned and your git config has been setup."
echo "The project was cloned to the $HOME/projects directory."
