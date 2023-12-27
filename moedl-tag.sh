#!/bin/bash

USE_TOR=false
DELAY=1
RECENT=false
URL="konachan.com"

function usage {
		echo "./$(basename "$0") [-t] [-s] [-r] [-c site.com]"
        echo "Mass downloader for moebooru imageboards (think konachan and yande.re)"
		echo "Simply make a files.txt inside a folder and paste all your links, then run this script to download them all!"
        echo "	-h	shows this help message"
		echo "	-t	downloads using tor (requires torsocks)"
		echo "	-s	sets the delay after each request, defaults to 1"
		echo "	-a	tag or artist name"
		echo "	-r	will download until it hits a file that already exists"
		echo "	-c	custom url (defaults to konachan if unset)"
}

# list of arguments expected in the input
optstring=":hts:a:rc:"

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
		a)
			TAGS+=("$OPTARG")
			;;
		r)
			RECENT=true
			;;
		c)
			URL="${OPTARG}"
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

for TAG in "${TAGS[@]}"; do
	echo "$TAG"
	# CREATE FOLDER AND CD INTO IT
	mkdir -v "$TAG"
	cd "$TAG" || exit
	if $USE_TOR; then
		TAG_COUNT=$(torsocks curl -s "https://$URL/tag.json?name=$TAG" | jq -r '.[]."count"')
	else
		TAG_COUNT=$(curl -s "https://$URL/tag.json?name=$TAG" | jq -r '.[]."count"')
	fi
	# NESTED LOOP TO GET ALL POSTS UNDER TAG
	TAG_PAGES=$((TAG_COUNT / 100))
	ID_LIST=""
	for (( PAGE = 0; PAGE <= TAG_PAGES; PAGE++ ))
	do
		if $USE_TOR; then
			ID_LIST+=$(torsocks curl -s "https://$URL/post.json?page=$PAGE&limit=100&tags=$TAG" | jq -r '.[]."id"')
			if ((PAGE < TAG_PAGES)); then
				ID_LIST+=$'\n'
			fi
		else
			ID_LIST+=$(curl -s "https://$URL/post.json?page=$PAGE&limit=100&tags=$TAG" | jq -r '.[]."id"')
			if ((PAGE < TAG_PAGES)); then
				ID_LIST+=$'\n'
			fi
		fi
		sleep "$DELAY"
	done
	echo "$ID_LIST" | while read -r IMAGE_ID; do
		# DOWNLOAD JSON
		if $USE_TOR; then
			JSON=$(torsocks curl -s "https://$URL/post.json?tags=id:$IMAGE_ID")
		else
			JSON=$(curl -s "https://$URL/post.json?tags=id:$IMAGE_ID")
		fi
		# STORE FILE URL AND TAGS INTO VARIABLES
		FILE_DATE=$(echo "$JSON" | jq -r '.[]."created_at"')
		FILE_URL=$(echo "$JSON" | jq -r '.[] | ."file_url"')
		FILE_TAGS=$(echo "$JSON" | jq -r '.[] | ."tags"' | sed 's/\ /,/g')
		FILE=$(echo "$JSON" | jq -r '.[] | ."file_url"' | sed 's/\// /g' | awk '{print $5}')
		FILE_WITHSPACE=$(echo "$JSON" | jq -r '.[] | ."file_url"' | sed 's/\// /g' | awk '{print $5}' | sed 's/\%20/ /g')
		if $RECENT; then
			if [[ -f "$FILE_WITHSPACE" ]]; then
				echo "$FILE_WITHSPACE exists."
				exit
			fi
		fi
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
		touch -d "@$FILE_DATE" "$FILE_WITHSPACE"
		sleep "$DELAY"
	done
	# BACK OUT OF FOLDER
	cd ..
done