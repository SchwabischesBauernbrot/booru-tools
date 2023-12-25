#!/bin/bash

USE_TOR=false
DELAY=1
UA="Booru-Tools/0.1"

function usage {
		echo "./$(basename "$0") [-t] [-s]"
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
	FILE_MD5=$(md5sum "$FILE" | awk '{print $1}')
	echo "$FILE_MD5"
	# DOWNLOAD JSON
	if $USE_TOR; then
		#JSON=`torsocks curl -A "$UA" -s "https://e621.net/posts.json?tags=md5:$FILE_MD5"`
		echo "e621 BLOCKS TOR WITH CLOUDFLARE"
		echo "EXITING SINCE SCRIPT WILL NOT WORK"
		exit
	else
		JSON=$(curl -s -A "$UA" "https://e621.net/posts.json?limit=1&tags=md5:$FILE_MD5")
	fi
	# ONE JQ TO RULE THEM ALL (modified)
	FILE_TAGS=$(jq -r '.posts | .[] | ."tags" | reduce to_entries[] as $arr ([]; . + [ $arr.value[] | gsub("[\"\\[\\]\\s]"; "", "g") ] ) | join(",")' - <<< "$JSON")
	#echo "$FILE_TAGS"
	# ADD TAGS TO IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	# DELAY BEFORE NEXT FETCH
	sleep "$DELAY"
done