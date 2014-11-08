#!/bin/bash
# -------
# Script for apply AMPs to installed WAR
# 
# Copyright 2013 Loftux AB, Peter Löfgren
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64/"
export JRE_HOME=$JAVA_HOME/jre
export PATH=$PATH:$HOME/bin:$JRE_HOME/bin
export ALF_HOME=/opt/alfresco
export CATALINA_HOME=/var/lib/tomcat7
export CATALINA_PID="${ALF_HOME}/tomcat.pid"
export USER=tomcat7

cd $ALF_HOME/addons

#Create directories if not exist
if [ ! -d "share" ]; then
	mkdir share
fi
if [ ! -d "alfresco" ]; then
	mkdir alfresco
fi
if [ ! -d "war" ]; then
	mkdir war
fi

amp(){
if [ -e war/alfresco.war ]; then
	if [ -e alfresco.war ]; then
		rm alfresco.war
	fi
	cp war/alfresco.war .
	# Use ls listing instead of -directory option, that way we can control order amps is applied
	for file in `ls -v alfresco/*.amp`;
	do
  	if [[ ! -f "$file" ]]
  		then
    	continue
  	fi
  		echo "Applying $file"
		java -jar alfresco-mmt.jar install $file alfresco.war -force -nobackup                                                       
	done
	
else
	echo "Skipping alfresco.war - not present in war directory"
fi
if [ -e war/share.war ]; then
	if [ -e share.war ]; then
		rm share.war
	fi
	cp war/share.war .
	# Use ls listing instead of -directory option, that way we can control order amps is applied
	for file in `ls -v share/*.amp`;
	do
  	if [[ ! -f "$file" ]]
  		then
    	continue
  	fi
  		echo "Applying $file"
		java -jar alfresco-mmt.jar install $file share.war -force -nobackup                                                       
	done
else
	echo "Skipping share.war - not present in war directory"
fi

# List the installed war files
if [ -e alfresco.war ]; then
	java -jar alfresco-mmt.jar list alfresco.war
fi
if [ -e share.war ]; then
	java -jar alfresco-mmt.jar list share.war
fi
}

copy(){
	echo "------------------------"
	echo "Copying new war files..."
        service tomcat7 stop
	if [ -e $CATALINA_HOME/webapps/alfresco.war.old ]; then
		rm $CATALINA_HOME/webapps/alfresco.war.old
	fi
	if [ -e alfresco.war ]; then
		if [ -e $CATALINA_HOME/webapps/alfresco.war ]; then
			echo "Backing up existing alfresco.war"
			mv $CATALINA_HOME/webapps/alfresco.war $CATALINA_HOME/webapps/alfresco.war.old
		fi
		echo "Moving new alfresco.war to tomcat..."
		mv alfresco.war $CATALINA_HOME/webapps/alfresco.war
	fi
	if [ -e $CATALINA_HOME/webapps/share.war.old ]; then
		rm $CATALINA_HOME/webapps/share.war.old
	fi
	if [ -e share.war ]; then
		if [ -e $CATALINA_HOME/webapps/share.war ]; then
			echo "Backing up existing share.war"
			mv $CATALINA_HOME/webapps/share.war $CATALINA_HOME/webapps/share.war.old
		fi
		echo "Moving new share.war to tomcat..."
		mv share.war $CATALINA_HOME/webapps/share.war
	fi
	echo "Cleaning temporary Alfresco files from Tomcat..."
	rm -rf ${CATALINA_HOME}/work/Alfresco
	rm -rf ${CATALINA_HOME}/webapps/alfresco
	rm -rf ${CATALINA_HOME}/webapps/share
	echo "Restoring permissions on Tomcat"
	chown -R ${USER}:${USER} ${CATALINA_HOME}
}

case "$1" in
    amp)
    	amp
    	;;
    copy)
        copy
        ;;
    all)
    	amp
    	copy
    	;;
    *)
      	echo "Apply amps to war files"
      	echo "Put amp files in share and alfresco respectively. Put alfresco.war and share.war in source"
      	echo "Completed war files will be put in ${PWD}"
      	echo " amp: Merge amp files into war files"
      	echo " copy: Copy the new war files to tomcat"
      	echo " all: Run amp and copy targets"
        echo "Usage: $0 {amp|copy|all}"
        exit 1
    esac
