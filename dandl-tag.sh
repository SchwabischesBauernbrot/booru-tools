#!/bin/bash

USE_TOR=false
DELAY=1
RESUME=false

function usage {
		echo "./$(basename "$0") [-t] [-s] [-r]"
        echo "Mass downloader for Danbooru"
		echo "Simply make a files.txt inside a folder and paste all your links, then run this script to download them all!"
        echo "	-h	shows this help message"
		echo "	-t	downloads using tor (requires torsocks)"
		echo "	-s	sets the delay after each request, defaults to 1"
		echo "	-a	tag or artist name"
		echo "	-r	will download until it hits a file that already exists"
}

# list of arguments expected in the input
optstring=":hts:a:r"

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
			RESUME=true
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
	# GET TAG TOTAL COUNT
	if $USE_TOR; then
		TAG_COUNT=$(torsocks curl -s "https://danbooru.donmai.us/tags.json?only=id,name,post_count&search\[name_matches\]=$TAG" | jq -r '.[].post_count')
	else
		TAG_COUNT=$(curl -s "https://danbooru.donmai.us/tags.json?only=id,name,post_count&search\[name_matches\]=$TAG" | jq -r '.[].post_count')
	fi
	# NESTED LOOP TO GET ALL POSTS UNDER TAG
	TAG_PAGES=$((TAG_COUNT / 200))
	for (( PAGE = 0; PAGE <= TAG_PAGES; PAGE++ ))
	do
		if $USE_TOR; then
			JSON_URL+=$(torsocks curl -s "https://danbooru.donmai.us/posts.json?page=$PAGE&limit=200&tags=$TAG" | jq -r '.[].id')
			if ((PAGE < TAG_PAGES)); then
				JSON_URL+=$'\n'
			fi
		else
			JSON_URL+=$(curl -s "https://danbooru.donmai.us/posts.json?page=$PAGE&limit=200&tags=$TAG" | jq -r '.[].id')
			if ((PAGE < TAG_PAGES)); then
				JSON_URL+=$'\n'
			fi
		fi
		sleep "$DELAY"
	done
	# NESTED LOOP FOR IMAGES IN THIS TAG
	echo "$JSON_URL" | while read -r i; do
		if $USE_TOR; then
			JSON=$(torsocks curl -s "https://danbooru.donmai.us/posts/$i.json")
		else
			JSON=$(curl -s "https://danbooru.donmai.us/posts/$i.json")
		fi
		# STORE FILE URL AND TAGS INTO VARIABLES
		FILE_DATE=$(echo "$JSON" | jq -r '."created_at"')
		FILE_URL=$(echo "$JSON" | jq -r '."file_url"')
		FILE_TAGS=$(echo "$JSON"  | jq -r '."tag_string"' | sed 's/\ /,/g')
		FILE_MD5=$(echo "$JSON" | jq -r '.md5')
		FILE_EXT=$(echo "$JSON" | jq -r '.file_ext')
		FILE="$FILE_MD5.$FILE_EXT"
		if $RESUME; then
			if [[ -f "$FILE" ]]; then
				echo "$FILE exists."
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
		setfattr --name=user.checksum --value="$FILE_MD5" "$FILE"
		# SET TIME TO TIME UPLOADED
		touch -d "$FILE_DATE" "$FILE"
		# DELAY BEFORE NEXT FETCH
		sleep "$DELAY"
	done
	# BACK OUT OF FOLDER
	cd ..
done