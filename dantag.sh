#!/bin/bash

USE_TOR=false
DELAY=1
SEARCH_URL="https://danbooru.donmai.us/posts.json?tags=md5"

function usage {
		echo "./$(basename $0) [-t] [-s]"
        echo "Mass tagger for Danbooru"
		echo "Tags existing pictures inside a folder"
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

for FILE in *; do
	echo "$FILE"
	# GET MD5 HASH
	FILE_MD5=`md5sum "$FILE" | awk '{print $1}'`
	# DOWNLOAD JSON
		if $USE_TOR; then
		JSON=`torsocks curl -s "$SEARCH_URL:$FILE_MD5"`
	else
		JSON=`curl -s "$SEARCH_URL:$FILE_MD5"`
	fi
	# STORE TAGS INTO VARIABLES
	FILE_TAGS=`echo $JSON | jq -r '.[] | ."tag_string"' | sed 's/\ /,/g'`
	# ADD TAGS TO IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	# DELAY BEFORE NEXT FETCH
	sleep $DELAY
done