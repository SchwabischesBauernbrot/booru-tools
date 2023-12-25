#!/bin/bash

USE_TOR=false
DELAY=1

function usage {
		echo "./$(basename $0) [-t] [-s]"
        echo "Mass downloader for Danbooru"
		echo "Simply make a files.txt inside a folder and paste all your links, then run this script to download them all!"
        echo "	-h	shows this help message"
		echo "	-t	downloads using tor (requires torsocks)"
		echo "	-s	sets the delay after each request, defaults to 1"
}

# list of arguments expected in the input
optstring=":hts:"

while getopts ${optstring} arg; do
	case ${arg} in
		h)
			usage
			exit
			;;
		t)
			USE_TOR=true
			echo -n "Using Tor with IP: "
			torsocks curl ip.me
			;;
		s)
			DELAY="${OPTARG}"
			;;
		:)
			echo "$0: Must supply an argument to -$OPTARG." >&2
			exit 1
			;;
		?)
			echo "Invalid option: -${OPTARG}."
			exit 2
			;;
	esac
done

while read f; do
	echo "$f"
	# MODIFY URL TO API CALL
	JSON_URL=`echo $f | sed "s/\?q.*//g"`
	# DOWNLOAD JSON
	if $USE_TOR; then
		JSON=`torsocks curl -s "$JSON_URL.json"`
	else
		JSON=`curl -s "$JSON_URL.json"`
	fi
	# STORE FILE URL AND TAGS INTO VARIABLES
	FILE_URL=`echo $JSON | jq -r '."file_url"'`
	FILE_TAGS=`echo $JSON  | jq -r '."tag_string"' | sed 's/\ /,/g'`
    FILE_MD5=`echo $JSON | jq -r '.md5'`
	FILE_EXT=`echo $JSON | jq -r '.file_ext'`
    FILE="$FILE_MD5.$FILE_EXT"
	# DOWNLOAD FILE
	if $USE_TOR; then
		torsocks curl -O -J "$FILE_URL"
	else
		curl -O -J "$FILE_URL"
	fi
	# ADD TAGS TO NEW IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE_MD5"*
	setfattr --name=user.checksum --value="$FILE_MD5" "$FILE_MD5"*
	# DELAY BEFORE NEXT FETCH
	sleep $DELAY
done < files.txt