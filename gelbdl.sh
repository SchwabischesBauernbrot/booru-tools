#!/bin/bash

USE_TOR=false
DELAY=1

function usage {
		echo "./$(basename $0) [-t] [-s]"
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
	JSON_URL=`echo $f | sed 's/page=post/page=dapi\&json=1\&q=index/g' | sed 's/s=view/s=post/g' | sed "s/\&tags.*//g"`
	# DOWNLOAD JSON
	if $USE_TOR; then
		JSON=`torsocks curl -s $JSON_URL | jq .`
	else
		JSON=`curl -s $JSON_URL | jq .`
	fi
	# STORE FILE URL AND TAGS INTO VARIABLES
	FILE_URL=`echo $JSON | jq -r '.post | .[] | ."file_url"'`
	FILE_TAGS=`echo $JSON | jq -r '.post | .[] | ."tags"' | sed 's/\ /,/g'`
	FILE=`echo $JSON | jq -r '.post | .[] | ."image"'`
	# DOWNLOAD FILE
	if $USE_TOR; then
		torsocks curl -O -J $FILE_URL
	else
		curl -O -J $FILE_URL
	fi
	# ADD TAGS TO NEW IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	# DELAY BEFORE NEXT FETCH
	sleep $DELAY
done < files.txt