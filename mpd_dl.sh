#!/bin/bash

if [[ $# -eq 2 ]]
then
	MPD=$1
	FILENAME=$2
else
	echo "./mpd_dl.sh "url" "filename""
	exit 1
fi

#ID=$(curl -s $URL | tr " " "\n" | grep "data-id" | sed -E 's/data-id\=\"(.+)(\".*$)/\1/')
#ID=$(echo $URL | sed -E 's/^.*(.{8}$)/\1/')
#echo "ID:" $ID

#MEDIA_SELECTOR=$(cat urls)
#MEDIA_URL="$MEDIA_SELECTOR/$ID/format/json/"
#echo "MEDIA_URL:" $MEDIA_URL
#MPD=$(curl -s $MEDIA_URL | jq '.media[].connection[] | select(.priority == "20" and .transferFormat == "dash" and .protocol == "https").href' | tr -d \")
#MPD=$(curl -s -v $MEDIA_URL)
#echo "MPD:" $MPD

# get base url
BASE_URL=$(echo $MPD | sed 's/https:\/\///' | sed 's/\/pc_hd.*$//')
echo "BASE_URL:" $BASE_URL

# get dash url
DASH_URL=$(curl -s $MPD | tr " " "\n" | grep initialization | sed 's/initialization=//' | tr -d '"' | sed 's/\$RepresentationID\$/audio_eng_1=96000/')
echo "DASH_END:" $DASH_URL

# fetch dash
curl -s -o dash.dash $BASE_URL/$DASH_URL

# get parts url
N=1700
PARTS_END=$(echo $DASH_URL | sed 's/.dash//')

# fetch parts
for i in $(seq 1 $N)
do
	PARTS_URL=$BASE_URL/dash/$PARTS_END-$i.m4s
	curl -s -o parts/part$i.m4s $PARTS_URL
	echo "fetched part" $i
done

echo "putting together binaries..."
cat dash.dash > all.m4s
for i in $(seq 1 $N) do
	cat parts/part$i.m4s >> all.m4s
done

echo "converting to mp4..."
ffmpeg -y -i all.m4s -c copy sound.mp4

echo "converting to mp3..."
ffmpeg -i sound.mp4 -vn $FILENAME.mp3

echo "cleaning..."
rm dash.dash all.m4s sound.mp4
rm -r parts/

echo "done"

