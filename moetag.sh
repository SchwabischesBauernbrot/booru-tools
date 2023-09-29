#!/bin/bash

USE_TOR=false
DELAY=1
REQ_URL=""

function usage {
		echo "./$(basename $0) [-t] [-s]"
        echo "Mass tagger for moebooru imageboards"
		echo "Tags existing pictures inside a folder"
        echo "	-h	shows this help message"
		echo "	-t	downloads using tor (requires torsocks)"
		echo "	-s	sets the delay after each request, defaults to 1"
		echo "	-k	uses konachan API for tagging"
		echo "	-y	uses yande.re API for tagging"
        echo "	-c	uses (CUSTOM.URL) API for tagging"
}

# list of arguments expected in the input
optstring=":hts:kyc:"

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
        k)
			REQ_URL="https://konachan.com/post.json?tags=md5:"
			echo "Using konachan API for tagging"
			;;
        y)
			REQ_URL="https://yande.re/post.json?tags=md5:"
			echo "Using yande.re API for tagging"
			;;
        c)
			REQ_URL="https://$OPTARG/post.json?tags=md5:"
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

if [[ -z "$REQ_URL" ]]; then
   echo "No imageboard selected. Exiting."
   exit
fi

for FILE in *; do
	echo "$FILE"
	# GET MD5 HASH
	FILE_MD5=`md5sum "$FILE" | awk '{print $1}'`
	# DOWNLOAD JSON
		if $USE_TOR; then
		JSON=`torsocks curl -s "$REQ_URL$FILE_MD5"`
	else
		JSON=`curl -s "$REQ_URL$FILE_MD5"`
	fi
	# STORE TAGS INTO VARIABLES
	FILE_TAGS=`echo $JSON | jq -r '.[] | ."tags"' | sed 's/\ /,/g'`
	# ADD TAGS TO IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
	# DELAY BEFORE NEXT FETCH
	sleep $DELAY
done
