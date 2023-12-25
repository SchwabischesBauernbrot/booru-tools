#!/bin/bash

USE_TOR=false
DELAY=1
USE_DATE=false

function usage {
		echo "./$(basename "$0") [-t] [-s]"
        echo "Mass tagger for Gelbooru"
		echo "Tags existing pictures inside a folder"
        echo "	-h	shows this help message"
		echo "	-t	downloads using tor (requires torsocks)"
		echo "	-s	sets the delay after each request, defaults to 1"
		echo "	-d	sets the date of the file downloaded to the date it was uploaded to Gelbooru"

}

# list of arguments expected in the input
optstring=":hts:d"

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
		d)
			USE_DATE=true
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
	FILE_MD5=$(md5sum "$FILE" | awk '{print $1}')
	# DOWNLOAD JSON
		if $USE_TOR; then
		JSON=$(torsocks curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&tags=md5:$FILE_MD5" | jq .)
	else
		JSON=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&tags=md5:$FILE_MD5" | jq .)
	fi
	# STORE TAGS INTO VARIABLES
	FILE_TAGS=$(echo "$JSON" | jq -r '.post | .[] | ."tags"' | sed 's/\ /,/g')
	FILE_DATE=$(echo "$JSON" | jq -r '.post | .[] | ."created_at"')
	# ADD TAGS TO IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	if $USE_DATE; then
		touch -d "$FILE_DATE" "$FILE"
	fi
	# DELAY BEFORE NEXT FETCH
	sleep "$DELAY"
done