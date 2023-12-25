#!/bin/bash

USE_TOR=false
DELAY=1
USE_DATE=false

function usage {
		echo "./$(basename "$0") [-t] [-s 1] [-d]"
        echo "Mass downloader for Gelbooru"
		echo "Simply make a files.txt inside a folder and paste all your links, then run this script to download them all!"
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

while read -r f; do
	echo "$f"
	# MODIFY URL TO API CALL
	JSON_URL=$(echo "$f" | sed 's/page=post/page=dapi\&json=1\&q=index/g' | sed 's/s=view/s=post/g' | sed "s/\&tags.*//g")
	# DOWNLOAD JSON
	if $USE_TOR; then
		JSON=$(torsocks curl -s "$JSON_URL" | jq .)
	else
		JSON=$(curl -s "$JSON_URL" | jq .)
	fi
	# STORE FILE URL AND TAGS INTO VARIABLES
	FILE_URL=$(echo "$JSON" | jq -r '.post | .[] | ."file_url"')
	FILE_TAGS=$(echo "$JSON" | jq -r '.post | .[] | ."tags"' | sed 's/\ /,/g')
	FILE_MD5=$(echo "$JSON" | jq -r '.post | .[] | ."md5"')
	FILE_DATE=$(echo "$JSON" | jq -r '.post | .[] | ."created_at"')
	FILE=$(echo "$FILE_URL" | sed 's/\// /g' | awk '{print $NF}')
	# DOWNLOAD FILE
	if $USE_TOR; then
		torsocks curl -O -J "$FILE_URL"
	else
		curl -O -J "$FILE_URL"
	fi
	# ADD TAGS TO NEW IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	setfattr --name=user.checksum --value="$FILE_MD5" "$FILE"
	if $USE_DATE; then
		touch -d "$FILE_DATE" "$FILE"
	fi
	# DELAY BEFORE NEXT FETCH
	sleep "$DELAY"
done < files.txt