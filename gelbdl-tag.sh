#!/bin/bash

USE_TOR=false
DELAY=1
RECENT=false

function usage {
		echo "./$(basename "$0") [-t] [-s] [-r] -a tag -a tag2"
        echo "Mass downloader for Gelbooru"
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
			RECENT=true
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
		TAG_COUNT=$(torsocks curl -s "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&name=$TAG" | jq -r '."tag" | .[] | ."count"')
	else
		TAG_COUNT=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&name=$TAG" | jq -r '."tag" | .[] | ."count"')
	fi

	# NESTED LOOP TO GET ALL POSTS UNDER TAG
	TAG_PAGES=$((TAG_COUNT / 100))
	for (( PAGE = 0; PAGE <= TAG_PAGES; PAGE++ ))
	do
		if $USE_TOR; then
			JSON+=$(torsocks curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&pid=$PAGE&tags=$TAG" | jq -r '.post')
		else
			JSON+=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&pid=$PAGE&tags=$TAG" | jq -r '.post')
		fi
		sleep "$DELAY"
	done

	# NESTED LOOP FOR IMAGES IN THIS TAG
	echo "$JSON" | jq -c '.[]' | while read -r i; do
		#echo $i | jq -r '."id"'
		FILE_DATE=$(echo "$i" | jq -r '."created_at"')
		FILE_URL=$(echo "$i" | jq -r '."file_url"')
		FILE_MD5=$(echo "$i" | jq -r '."md5"')
		FILE_TAGS=$(echo "$i" | jq -r '."tags"' | sed 's/\ /,/g')
		FILE=$(echo "$FILE_URL" | sed 's/\// /g' | awk '{print $NF}')

		if $RECENT; then
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
		touch -d "$FILE_DATE" "$FILE"
		# DELAY BEFORE NEXT FETCH
		sleep "$DELAY"
	done
	# BACK OUT OF FOLDER
	cd ..
done