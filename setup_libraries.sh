#!/bin/bash

if ! which wget; then
	echo "You need wget to download required libraries"
	exit 1
fi

if ! which git; then
	echo "You need git to download required libraries"
	exit 1
fi

if ! which unzip; then
	echo "You need unzip to extract library packages"
	exit 1
fi

if ! which tar; then
	echo "You need tar to extract library packages"
	exit 1
fi

PROJECT_PATH=`pwd`
cd /tmp

if wget https://github.com/twbs/bootstrap/releases/download/v3.1.1/bootstrap-3.1.1-dist.zip ; then
	unzip bootstrap-3.1.1-dist.zip
	mkdir -p $PROJECT_PATH/web_root/libs
	mv bootstrap-3.1.1-dist $PROJECT_PATH/web_root/libs/bootstrap
	echo -e "\e[0;32mSuccess: \e[mInstalled bootstrap"
else
	echo -e "\e[0;31mError: \e[mError while downloading bootstrap"
	sleep 2
fi

if wget http://code.jquery.com/jquery-1.11.0.min.js ; then
	mkdir -p $PROJECT_PATH/web_root/libs/jquery
	mv jquery-1.11.0.min.js $PROJECT_PATH/web_root/libs/jquery/jquery.js
	echo -e "\e[0;32mSuccess: \e[mInstalled jquery"
else
	echo -e "\e[0;31mError: \e[mError while downloading jquery"
	sleep 2
fi

if wget http://code.angularjs.org/1.2.15/angular.js && wget http://code.angularjs.org/1.2.15/angular-resource.js && wget http://code.angularjs.org/1.2.15/angular-route.js ; then
	mkdir -p $PROJECT_PATH/web_root/libs/angular
	mv angular*.js $PROJECT_PATH/web_root/libs/angular
	echo -e "\e[0;32mSuccess: \e[mInstalled angular"
else
	echo -e "\e[0;31mERROR:   \e[mError while downloading angular"
	sleep 2
fi