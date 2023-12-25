#!/bin/bash

USE_TOR=false
DELAY=1
UA="Booru-Tools/0.1"

function usage {
		echo "./$(basename $0) [-t] [-s]"
		echo "Tags existing pictures inside a folder"
        echo "	-h	shows this help message"
		echo "	-t	e621 BLOCKS TOR WITH CLOUDFLARE, DOES NOT WORK"
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
			echo "e621 BLOCKS TOR WITH CLOUDFLARE"
			echo "EXITING SINCE SCRIPT WILL NOT WORK"
			exit
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
	echo $FILE_MD5
	# DOWNLOAD JSON
	URL=https://e621.net/posts.json?tags=md5:
	if $USE_TOR; then
		#JSON=`torsocks curl -A "$UA" -s "https://e621.net/posts.json?tags=md5:$FILE_MD5"`
		echo "e621 BLOCKS TOR WITH CLOUDFLARE"
		echo "EXITING SINCE SCRIPT WILL NOT WORK"
		exit
	else
		JSON=`curl -s -A "$UA" "https://e621.net/posts.json?tags=md5:$FILE_MD5"`
	fi
	# STORE TAGS INTO VARIABLES (god what the hell)
	FILE_TAGS_GENERAL=`echo $JSON | jq -r '.posts | .[] | ."tags"."general"' | sed 's/\"//g' | sed 's/\[//g' | sed 's/\]//g' | tr -d '[:space:]'`
	FILE_TAGS_ARTIST=`echo $JSON| jq -r '.posts | .[] | ."tags"."artist"' | sed 's/\"//g' | sed 's/\[//g' | sed 's/\]//g' | tr -d '[:space:]'`
	FILE_TAGS_CHARACTER=`echo $JSON| jq -r '.posts | .[] | ."tags"."character"' | sed 's/\"//g' | sed 's/\[//g' | sed 's/\]//g' | tr -d '[:space:]'`
	FILE_TAGS_SPECIES=`echo $JSON| jq -r '.posts | .[] | ."tags"."species"' | sed 's/\"//g' | sed 's/\[//g' | sed 's/\]//g' | tr -d '[:space:]'`
	FILE_TAGS_META=`echo $JSON| jq -r '.posts | .[] | ."tags"."meta"' | sed 's/\"//g' | sed 's/\[//g' | sed 's/\]//g' | tr -d '[:space:]'`
	FILE_TAGS=`echo "$FILE_TAGS_ARTIST,$FILE_TAGS_CHARACTER,$FILE_TAGS_GENERAL,$FILE_TAGS_SPECIES,$FILE_TAGS_META"`
	echo $FILE_TAGS
	# ADD TAGS TO IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	setfattr -n user.xdg.creator -v "$FILE_TAGS_ARTIST" "$FILE"
	# DELAY BEFORE NEXT FETCH
	sleep $DELAY
done