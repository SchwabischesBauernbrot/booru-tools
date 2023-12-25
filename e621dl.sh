#!/bin/bash

USE_TOR=false
DELAY=1
UA="Booru-Tools/0.1"
HAS_USERNAME=false
HAS_API_KEY=false


function usage {
		echo "./$(basename "$0") [-t] [-s]"
		echo "Simply make a files.txt inside a folder and paste all your links, then run this script to download them all!"
        echo "	-h	shows this help message"
		echo "	-t	e621 BLOCKS TOR WITH CLOUDFLARE, DOES NOT WORK"
		echo "	-p	downloads using proxy"
		echo "	-s	sets the delay after each request, defaults to 1"
		echo "	-u	e621.net username"
		echo "	-k	e621.net API key"
}

# list of arguments expected in the input
optstring=":hts:u:k:"

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
		u)
			HAS_USERNAME=true
			USERNAME="${OPTARG}"
			;;
		k)
			HAS_API_KEY=true
			API_KEY="${OPTARG}"
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
	# shellcheck disable=SC2001
	JSON_URL=$(echo "$f" | sed "s/\?q.*//g")
	JSON_URL="$JSON_URL.json"
	# DOWNLOAD JSON
	if $HAS_USERNAME && $HAS_API_KEY ; then
		JSON_URL="$JSON_URL?login=$USERNAME&api_key=$API_KEY"
	fi
	echo "$JSON_URL"
	if $USE_TOR; then
		#JSON=`torsocks curl -A "$UA" -s "$JSON_URL"`
		echo "e621 BLOCKS TOR WITH CLOUDFLARE"
		echo "EXITING SINCE SCRIPT WILL NOT WORK"
		exit
	else
		JSON=$(curl -A "$UA" -s "$JSON_URL")
	fi
	# STORE TAGS INTO VARIABLES
	#FILE_DESCRIPTION=`echo $JSON | jq -r '.post'.'description'`
	FILE_URL=$(echo "$JSON" | jq -r '.post | .file."url"')
	FILE_MD5=$(echo "$JSON" | jq -r '.post'.'file'.'md5')
	FILE_EXT=$(echo "$JSON" | jq -r '.post'.'file'.'ext')
	# ONE JQ TO RULE THEM ALL (thanks jon!)
	FILE_TAGS="$(jq -r '.post.tags | reduce to_entries[] as $arr ([]; . + [ $arr.value[] | gsub("[\"\\[\\]\\s]"; "", "g") ] ) | join(",")' - <<< "$JSON")"

	#echo $FILE_TAGS
	# DOWNLOAD FILE
	if $USE_TOR; then
		#torsocks curl -O -J $FILE_URL
		echo "e621 BLOCKS TOR WITH CLOUDFLARE"
		echo "EXITING SINCE SCRIPT WILL NOT WORK"
		exit
	else
		curl -O -J "$FILE_URL"
	fi
	# ADD TAGS TO NEW IMAGE
	FILE="$FILE_MD5.$FILE_EXT"
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	setfattr -n user.xdg.creator -v "$FILE_TAGS_ARTIST" "$FILE"
	setfattr -n user.xdg.comment -v "$FILE_DESCRIPTION" "$FILE"
	setfattr --name=user.checksum --value="$FILE_MD5" "$FILE"
	# DELAY BEFORE NEXT FETCH
	sleep "$DELAY"
done < files.txt