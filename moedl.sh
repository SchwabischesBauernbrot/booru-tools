#!/bin/bash

USE_TOR=false
DELAY=1

function usage {
		echo "./$(basename $0) [-t] [-s]"
        echo "Mass downloader for moebooru imageboards (think konachan and yande.re)"
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
	# get ID from the URL
	URL=`echo $f | sed 's/\// /g' | awk '{print $2}'`
	IMAGE_ID=`echo $f | sed 's/\// /g' | awk '{print $5}'`
	# DOWNLOAD JSON
	if $USE_TOR; then
		JSON=`torsocks curl -s "https://$URL/post.json?tags=id:$IMAGE_ID"`
	else
		JSON=`curl -s "https://$URL/post.json?tags=id:$IMAGE_ID"`
	fi
	# STORE FILE URL AND TAGS INTO VARIABLES
	FILE_URL=`echo $JSON | jq -r '.[] | ."file_url"'`
	FILE_TAGS=`echo $JSON | jq -r '.[] | ."tags"' | sed 's/\ /,/g'`
    FILE=`echo $JSON | jq -r '.[] | ."file_url"' | sed 's/\// /g' | awk '{print $5}'`
    FILE_WITHSPACE=`echo $JSON | jq -r '.[] | ."file_url"' | sed 's/\// /g' | awk '{print $5}' | sed 's/\%20/ /g'`
	# DOWNLOAD FILE
	if $USE_TOR; then
		torsocks curl -O -J "$FILE_URL"
	else
		curl -O -J "$FILE_URL"
	fi
	# ADD TAGS TO NEW IMAGE
	setfattr -n user.xdg.tags -v "$FILE_TAGS" "$FILE"
    mv "$FILE" "$FILE_WITHSPACE"
	# DELAY BEFORE NEXT FETCH
	sleep $DELAY
done < files.txt