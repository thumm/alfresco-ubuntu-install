#!/bin/bash
# -------
# Script for install of Alfresco
#
# Copyright 2013-2014 Loftux AB, Peter Löfgren
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

export ALF_HOME=/opt/alfresco
export ALF_LIB=/var/lib/alfresco
export CATALINA_HOME=/usr/share/tomcat7
export CATALINA_BASE=/var/lib/tomcat7
export ALF_USER=tomcat7
pushd $(dirname $0)
export SCRIPT_DIR=$(pwd)
export CURL_DIR="file://${SCRIPT_DIR}"
popd

export APTVERBOSITY="-qq -y"

export BASE_DOWNLOAD=https://raw.githubusercontent.com/loftuxab/alfresco-ubuntu-install/master
export KEYSTOREBASE=http://svn.alfresco.com/repos/alfresco-open-mirror/alfresco/HEAD/root/projects/repository/config/alfresco/keystore

#Change this to prefered locale to make sure it exists. This has impact on LibreOffice transformations
export LOCALESUPPORT=de_DE.utf8

export JDBCPOSTGRESURL=http://jdbc.postgresql.org/download
export JDBCPOSTGRES=postgresql-9.3-1102.jdbc41.jar

export LIBREOFFICE=http://download.documentfoundation.org/libreoffice/stable/4.2.7/deb/x86_64/LibreOffice_4.2.7_Linux_x86-64_deb.tar.gz
export SWFTOOLS=http://www.swftools.org/swftools-2013-04-09-1007.tar.gz

export ALFWARZIP=http://dl.alfresco.com/release/community/5.0.b-build-00092/alfresco-community-5.0.b.zip
export GOOGLEDOCSREPO=http://dl.alfresco.com/release/community/5.0.b-build-00092/alfresco-googledocs-repo-2.0.8.amp
export GOOGLEDOCSSHARE=http://dl.alfresco.com/release/community/5.0.b-build-00092/alfresco-googledocs-share-2.0.8.amp
export SOLR=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/alfresco-solr/5.0.b/alfresco-solr-5.0.b-config.zip
export SPP=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/alfresco-spp/5.0.b/alfresco-spp-5.0.b.amp

# Color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

echoblue () {
  echo "${bldblu}$1${txtrst}"
}
echored () {
  echo "${bldred}$1${txtrst}"
}
echogreen () {
  echo "${bldgre}$1${txtrst}"
}
cd /tmp
if [ -d "alfrescoinstall" ]; then
	rm -rf alfrescoinstall
fi
mkdir alfrescoinstall
cd ./alfrescoinstall

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Alfresco Ubuntu installer by Loftux AB."
echogreen "Please read the documentation at"
echogreen "https://github.com/loftuxab/alfresco-ubuntu-install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Checking for the availability of the URLs inside script..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

URLERROR=0

for REMOTE in $JDBCPOSTGRESURL/$JDBCPOSTGRES \
        $LIBREOFFICE $SWFTOOLS $ALFWARZIP $GOOGLEDOCSREPO $GOOGLEDOCSSHARE $SOLR $SPP

do
        wget --spider $REMOTE  >& /dev/null
        if [ $? != 0 ]
        then
                echored "In alfinstall.sh, please fix this URL: $REMOTE"
                URLERROR=1
        fi
done

if [ $URLERROR = 1 ]
then
    echo
    echored "Please fix the above errors and rerun."
    echo
    exit
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Preparing for install. Updating the apt package index files..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY update;
echo

if [ "`which curl`" = "" ]; then
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to install curl. Curl is used for downloading components to install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY install curl;
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Ubuntu default for number of allowed open files in the file system is too low"
echo "for alfresco use and tomcat may because of this stop with the error"
echo "\"too many open files\". You should update this value if you have not done so."
echo "Read more at http://wiki.alfresco.com/wiki/Too_many_open_files"
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add limits.conf${ques} [y/n] " -i "n" updatelimits
if [ "$updatelimits" = "y" ]; then
  echo "tomcat7 soft  nofile  8192" | sudo tee -a /etc/security/limits.conf
  echo "tomcat7 hard  nofile  65536" | sudo tee -a /etc/security/limits.conf
  echo
  echogreen "Updated limits.conf"
  echo
else
  echo "Skipped updating limits.conf"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Tomcat is the application server that runs Alfresco."
echo "You will also get the option to install jdbc lib for Postgresql or MySql/MariaDB."
echo "Install the jdbc lib for the database you intend to use."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Tomcat${ques} [y/n] " -i "n" installtomcat

if [ "$installtomcat" = "y" ]; then
  echogreen "Installing Tomcat"
  echo "Installing tomcat..."
  sudo apt-get $APTVERBOSITY install tomcat7 tomcat7-admin
  echo

  sudo service tomcat7 stop
  echo
  sudo mkdir -p /etc/tomcat7/Catalina/alfresco.zuhause.xx
  sudo mv /etc/tomcat7/Catalina/localhost/* /etc/tomcat7/Catalina/alfresco.zuhause.xx

  echo
  read -e -p "Install Postgres JDBC Connector${ques} [y/n] " -i "n" installpg
  if [ "$installpg" = "y" ]; then
	curl -# -O $JDBCPOSTGRESURL/$JDBCPOSTGRES
	sudo mv $JDBCPOSTGRES $CATALINA_HOME/lib
  fi
  echo
  read -e -p "Install Mysql JDBC Connector${ques} [y/n] " -i "n" installmy
  if [ "$installmy" = "y" ]; then
    sudo apt-get install $APTVERBOSITY libmysql-java
    sudo ln -s /usr/share/java/mysql-connector-java.jar $CATALINA_HOME/lib
  fi
  sudo chown -R $ALF_USER:$ALF_USER $CATALINA_BASE
  echo
  echogreen "Finished installing Tomcat"
  echo
else
  echo "Skipping install of Tomcat"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Java JDK."
echo "This will install the OpenJDK version of Java. If you prefer Oracle Java"
echo "you need to download and install that manually."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install OpenJDK7${ques} [y/n] " -i "n" installjdk
if [ "$installjdk" = "y" ]; then
  echoblue "Installing OpenJDK7. Fetching packages..."
  sudo apt-get $APTVERBOSITY install openjdk-7-jdk
  echo
  echogreen "Finished installing OpenJDK"
  echo
else
  echo "Skipping install of OpenJDK 7"
  echored "IMPORTANT: You need to install other JDK and adjust paths for the install to be complete"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install LibreOffice."
echo "This will download and install the latest LibreOffice from libreoffice.org"
echo "Newer version of Libreoffice has better document filters, and produce better"
echo "transformations. If you prefer to use Ubuntu standard packages you can skip"
echo "this install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install LibreOffice${ques} [y/n] " -i "n" installibreoffice
if [ "$installibreoffice" = "y" ]; then

  cd /tmp/alfrescoinstall
  curl -# -L -O $LIBREOFFICE
  tar xf LibreOffice*.tar.gz
  cd "$(find . -type d -name "LibreOffice*")"
  cd DEBS
  sudo dpkg -i *.deb
  echo
  echoblue "Installing some support fonts for better transformations."
  sudo apt-get $APTVERBOSITY install ttf-mscorefonts-installer fonts-droid
  echo
  echogreen "Finished installing LibreOffice"
  echo
else
  echo
  echo "Skipping install of LibreOffice"
  echored "If you install LibreOffice/OpenOffice separetely, remember to update alfresco-global.properties"
  echored "Also run: sudo apt-get install ttf-mscorefonts-installer fonts-droid"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install ImageMagick."
echo "This will ImageMagick from Ubuntu packages."
echo "It is recommended that you install ImageMagick."
echo "If you prefer some other way of installing ImageMagick, skip this step."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install ImageMagick${ques} [y/n] " -i "n" installimagemagick
if [ "$installimagemagick" = "y" ]; then

  echoblue "Installing ImageMagick. Fetching packages..."
  sudo apt-get $APTVERBOSITY install imagemagick ghostscript libgs-dev libjpeg62 libpng3
  echo
  IMAGEMAGICKVERSION=`ls /usr/lib/|grep -i imagemagick`
  echoblue "Creating symbolic link for ImageMagick."
  sudo ln -s /usr/lib/$IMAGEMAGICKVERSION /usr/lib/ImageMagick
  echo
  echogreen "Finished installing ImageMagick"
  echo
else
  echo
  echo "Skipping install of ImageMagick"
  echored "Remember to install ImageMagick later. It is needed for thumbnail transformations."
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Swftools."
echo "This will download and install swftools used for transformations to Flash."
echo "Since the swftools Ubuntu package is not included in all versions of Ubuntu,"
echo "this install downloads from swftools.org and compiles."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Swftools${ques} [y/n] " -i "n" installswftools

if [ "$installswftools" = "y" ]; then
  echoblue "Installing build tools and libraries needed to compile swftools. Fetching packages..."
  sudo apt-get $APTVERBOSITY install make build-essential ccache g++ libgif-dev libjpeg62-dev libfreetype6-dev libpng12-dev libt1-dev
  cd /tmp/alfrescoinstall
  echo "Downloading swftools..."
  curl -# -O $SWFTOOLS
  tar xf swftools*.tar.gz
  cd "$(find . -type d -name "swftools*")"
  ./configure
  sudo make && sudo make install
  echo
  echogreen "Finished installing Swftools"
  echo
else
  echo
  echo "Skipping install of Swftools."
  echored "Remember to install swftools via Ubuntu packages or by any other mean."
  echo
fi

echo
echoblue "Adding basic support files. Always installed if not present."
echo
# Always add the addons dir and scripts
  sudo mkdir -p $ALF_HOME/addons/war
  sudo mkdir -p $ALF_HOME/addons/share
  sudo mkdir -p $ALF_HOME/addons/alfresco
  if [ ! -f "$ALF_HOME/addons/apply.sh" ]; then
    echo "Downloading apply.sh script..."
    sudo curl -o $ALF_HOME/addons/apply.sh $CURL_DIR/scripts/apply.sh
    sudo chmod u+x $ALF_HOME/addons/apply.sh
  fi
  if [ ! -f "$ALF_HOME/addons/alfresco-mmt.jar" ]; then
    sudo curl -o $ALF_HOME/addons/alfresco-mmt.jar $CURL_DIR/scripts/alfresco-mmt.jar
  fi

  sudo mkdir -p $ALF_HOME/scripts
  if [ ! -f "$ALF_HOME/scripts/mariadb.sh" ]; then
    echo "Downloading mariadb.sh install and setup script..."
    sudo curl -o $ALF_HOME/scripts/mariadb.sh $CURL_DIR/scripts/mariadb.sh
  fi
  if [ ! -f "$ALF_HOME/scripts/postgresql.sh" ]; then
    echo "Downloading postgresql.sh install and setup script..."
    sudo curl -o $ALF_HOME/scripts/postgresql.sh $CURL_DIR/scripts/postgresql.sh
  fi
  if [ ! -f "$ALF_HOME/scripts/limitconvert.sh" ]; then
    echo "Downloading limitconvert.sh script..."
    sudo curl -o $ALF_HOME/scripts/limitconvert.sh $CURL_DIR/scripts/limitconvert.sh
  fi
  if [ ! -f "$ALF_HOME/scripts/createssl.sh" ]; then
    echo "Downloading createssl.sh script..."
    sudo curl -o $ALF_HOME/scripts/createssl.sh $CURL_DIR/scripts/createssl.sh
  fi
  if [ ! -f "$ALF_HOME/scripts/libreoffice.sh" ]; then
    echo "Downloading libreoffice.sh script..."
    sudo curl -# -o $ALF_HOME/scripts/libreoffice.sh $CURL_DIR/scripts/libreoffice.sh
    sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $ALF_HOME/scripts/libreoffice.sh
  fi
  if [ ! -f "$ALF_HOME/scripts/iptables.sh" ]; then
    echo "Downloading iptables.sh script..."
    sudo curl -o $ALF_HOME/scripts/iptables.sh $CURL_DIR/scripts/iptables.sh
  fi
  if [ ! -f "$ALF_HOME/scripts/alfresco-iptables.conf" ]; then
    echo "Downloading alfresco-iptables.conf upstart script..."
    sudo curl -o $ALF_HOME/scripts/alfresco-iptables.conf $CURL_DIR/scripts/alfresco-iptables.conf
  fi
  if [ ! -f "$ALF_HOME/scripts/ams.sh" ]; then
    echo "Downloading maintenance shutdown script..."
    sudo curl -o $ALF_HOME/scripts/ams.sh $CURL_DIR/scripts/ams.sh
  fi
  sudo chmod u+x $ALF_HOME/scripts/*.sh
  sudo chown -R tomcat7:tomcat7 $ALF_HOME

  # Keystore
  sudo mkdir -p $ALF_LIB/keystore
  # Only check for precesence of one file, assume all the rest exists as well if so.
  if [ ! -f "$ALF_LIB/keystore/ssl.keystore" ]; then
    echo "Downloading keystore files..."
    sudo curl -# -o $ALF_LIB/keystore/browser.p12 $KEYSTOREBASE/browser.p12
    sudo curl -# -o $ALF_LIB/keystore/generate_keystores.sh $KEYSTOREBASE/generate_keystores.sh
    sudo curl -# -o $ALF_LIB/keystore/keystore $KEYSTOREBASE/keystore
    sudo curl -# -o $ALF_LIB/keystore/keystore-passwords.properties $KEYSTOREBASE/keystore-passwords.properties
    sudo curl -# -o $ALF_LIB/keystore/ssl-keystore-passwords.properties $KEYSTOREBASE/ssl-keystore-passwords.properties
    sudo curl -# -o $ALF_LIB/keystore/ssl-truststore-passwords.properties $KEYSTOREBASE/ssl-truststore-passwords.properties
    sudo curl -# -o $ALF_LIB/keystore/ssl.keystore $KEYSTOREBASE/ssl.keystore
    sudo curl -# -o $ALF_LIB/keystore/ssl.truststore $KEYSTOREBASE/ssl.truststore
    sudo chown -R tomcat7:tomcat7 $ALF_LIB
  fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Alfresco war files."
echo "Download war files and optional addons."
echo "If you have downloaded your war files you can skip this step add them manually."
echo "This install place downloaded files in the $ALF_HOME/addons and then use the"
echo "apply.sh script to add them to tomcat/webapps. Se this script for more info."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add Alfresco war files${ques} [y/n] " -i "n" installwar
if [ "$installwar" = "y" ]; then

  # Make extract dir
  mkdir -p /tmp/alfrescoinstall/war
  cd /tmp/alfrescoinstall/war

  sudo apt-get $APTVERBOSITY install unzip zip
  echo "Downloading war files..."
  curl -# -o /tmp/alfrescoinstall/war/alfwar.zip $ALFWARZIP
  unzip -q -j alfwar.zip $(unzip -l alfwar.zip | grep "\.war" | cut -c 3- | cut -d " " -f 7)
  sudo cp /tmp/alfrescoinstall/war/*.war $ALF_HOME/addons/war/
  sudo rm -rf /tmp/alfrescoinstall/war

  cd /tmp/alfrescoinstall
  read -e -p "Add Google docs integration${ques} [y/n] " -i "n" installgoogledocs
  if [ "$installgoogledocs" = "y" ]; then
  	echo "Downloading Google docs addon..."
    curl -# -O $GOOGLEDOCSREPO
    sudo mv alfresco-googledocs-repo*.amp $ALF_HOME/addons/alfresco/
    curl -# -O $GOOGLEDOCSSHARE
    sudo mv alfresco-googledocs-share* $ALF_HOME/addons/share/
  fi

  read -e -p "Add Sharepoint plugin${ques} [y/n] " -i "n" installspp
  if [ "$installspp" = "y" ]; then
    echo "Downloading Sharepoint addon..."
    curl -# -O $SPP
    sudo mv alfresco-spp*.amp $ALF_HOME/addons/alfresco/
  fi

  mkdir -p /tmp/alfrescoinstall/amp/alfresco/config
  cp -a $SCRIPT_DIR/var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/* /tmp/alfrescoinstall/amp/alfresco/config/
  echo "module.id=xx.zuhause.alfresco.alfresco" > /tmp/alfrescoinstall/amp/alfresco/module.properties
  echo "module.version=1.0.0" >> /tmp/alfrescoinstall/amp/alfresco/module.properties
  echo "module.buildnumber=SNAPSHOT" >> /tmp/alfrescoinstall/amp/alfresco/module.properties
  echo "module.title=Alfresco Anpassungen" >> /tmp/alfrescoinstall/amp/alfresco/module.properties
  echo "module.description=Alfresco Anpassungen" >> /tmp/alfrescoinstall/amp/alfresco/module.properties
  echo "module.repo.version.min=4.2.0" >> /tmp/alfrescoinstall/amp/alfresco/module.properties
  cd /tmp/alfrescoinstall/amp/alfresco
  zip -r $ALF_HOME/addons/alfresco/myalfresco.amp .

  mkdir -p /tmp/alfrescoinstall/amp/share/config
  cp -a $SCRIPT_DIR/var/lib/tomcat7/webapps/share/WEB-INF/classes/* /tmp/alfrescoinstall/amp/share/config/
  echo "module.id=xx.zuhause.alfresco.share" > /tmp/alfrescoinstall/amp/share/module.properties
  echo "module.version=1.0.0" >> /tmp/alfrescoinstall/amp/share/module.properties
  echo "module.buildnumber=SNAPSHOT" >> /tmp/alfrescoinstall/amp/share/module.properties
  echo "module.title=Alfresco share Anpassungen" >> /tmp/alfrescoinstall/amp/share/module.properties
  echo "module.description=Alfresco share Anpassungen" >> /tmp/alfrescoinstall/amp/share/module.properties
  echo "module.repo.version.min=4.2.0" >> /tmp/alfrescoinstall/amp/share/module.properties
  cd /tmp/alfrescoinstall/amp/share
  zip -r $ALF_HOME/addons/share/myshare.amp .

  cd $SCRIPT_DIR
  rm -rf /tmp/alfrescoinstall/amp

  sudo $ALF_HOME/addons/apply.sh all

  echo "Downloading alfresco configuration..."
  cd $SCRIPT_DIR
  sudo cp -a etc opt /
  sudo cp -a var/lib/alfresco /var/lib
  sudo cp -a var/lib/tomcat7/shared /var/lib/tomcat7

  echo
  echogreen "Finished adding Alfresco war files"
  echo
else
  echo
  echo "Skipping adding Alfresco war files"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Solr indexing engine."
echo "You have a choice lucene (default) or Solr as indexing engine."
echo "Solr runs as a separate application and is slightly more complex to configure."
echo "As Solr is more advanced and handle multilingual better it is recommended that"
echo "you install Solr."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Solr indexing engine${ques} [y/n] " -i "n" installsolr
if [ "$installsolr" = "y" ]; then

  sudo mkdir -p $ALF_HOME/solr
  sudo curl -# -o $ALF_HOME/solr/solr.zip $SOLR
  sudo cp $ALF_HOME/addons/war/apache-solr-1.4.1.war $ALF_HOME/solr/apache-solr-1.4.1.war
  cd $ALF_HOME/solr/

  sudo unzip -q -o solr.zip
  # Set the solr data path
  SOLRDATAPATH="$ALF_HOME/alf_data/solr"
  # Escape for sed
  SOLRDATAPATH="${SOLRDATAPATH//\//\\/}"

  sudo mv $ALF_HOME/solr/workspace-SpacesStore/conf/solrcore.properties $ALF_HOME/solr/workspace-SpacesStore/conf/solrcore.properties.orig
  sudo mv $ALF_HOME/solr/archive-SpacesStore/conf/solrcore.properties $ALF_HOME/solr/archive-SpacesStore/conf/solrcore.properties.orig
  sed "s/@@ALFRESCO_SOLR_DIR@@/$SOLRDATAPATH/g" $ALF_HOME/solr/workspace-SpacesStore/conf/solrcore.properties.orig > /tmp/alfrescoinstall/solrcore.properties
  sudo mv /tmp/alfrescoinstall/solrcore.properties $ALF_HOME/solr/workspace-SpacesStore/conf/solrcore.properties
  sed "s/@@ALFRESCO_SOLR_DIR@@/$SOLRDATAPATH/g" $ALF_HOME/solr/archive-SpacesStore/conf/solrcore.properties.orig > /tmp/alfrescoinstall/solrcore.properties
  sudo mv /tmp/alfrescoinstall/solrcore.properties $ALF_HOME/solr/archive-SpacesStore/conf/solrcore.properties
  SOLRDATAPATH="$ALF_HOME/solr"

  cd $SCRIPT_DIR
  sudo cp -a opt/alfresco/solr /opt/alfresco

  echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > /tmp/alfrescoinstall/solr.xml
  echo "<Context docBase=\"$ALF_HOME/solr/apache-solr-1.4.1.war\" debug=\"0\" crossContext=\"true\">" >> /tmp/alfrescoinstall/solr.xml
  echo "  <Environment name=\"solr/home\" type=\"java.lang.String\" value=\"$ALF_HOME/solr\" override=\"true\"/>" >> /tmp/alfrescoinstall/solr.xml
  echo "</Context>" >> /tmp/alfrescoinstall/solr.xml
  sudo mv /tmp/alfrescoinstall/solr.xml $CATALINA_BASE/conf/Catalina/alfresco.zuhause.xx/solr.xml

  echo
  echogreen "Finished installing Solr engine."
  echored "You must manually update alfresco-global.properties."
  echo "Set property value index.subsystem.name=solr"
  echo
else
  echo
  echo "Skipping installing Solr."
  echo "You can always install Solr at a later time."
  echo
fi

sudo chown -R $ALF_USER:$ALF_USER $ALF_HOME $ALF_LIB $CATALINA_BASE

echo
echogreen "- - - - - - - - - - - - - - - - -"
echo "Scripted install complete"
echored "Manual tasks remaining:"
echo "1. Add database. Install scripts available in $ALF_HOME/scripts"
echored "   It is however recommended that you use a separate database server."
echo "2. Verify Tomcat memory and locale settings in /etc/init/alfresco.conf."
echo "   Alfresco runs best with lots of memory. Add some more to \"lots\" and you will be fine!"
echo "   Match the locale LC_ALL (or remove) setting to the one used in this script."
echo "   Locale setting is needed for LibreOffice date handling support."
echo "3. Update database and other settings in alfresco-global.properties"
echo "   You will find this file in $CATALINA_BASE/shared/classes"
echo "4. Update cpu settings in $ALF_HOME/scripts/limitconvert.sh if you have more than 2 cores."
echo "5. Start nginx if you have installed it: /etc/init.d/nginx start"
echo "6. Start Alfresco/tomcat: sudo service alfresco start"
echo
