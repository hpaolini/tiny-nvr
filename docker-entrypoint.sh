#!/bin/bash
set -e

# return lowercase
function getLowercase () {
    echo "${1}" | tr "[:upper:]" "[:lower:]"
}

# convert string to boolean
function getBoolean () {
    case $(getLowercase "${1}") in
        "true") echo true ;;
        *) echo false ;;
    esac
}

# generate a random folder name in the form of "Camera_XXXX"
function getRandomName () {
    echo "Camera_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4 ; echo "")"
}

streamURL="${1}"
dirName="${2}"
dir="/usr/data/recordings"
fileExtension="mp4"

echo "Environment Variables:"
echo " TZ = $TZ"
echo " DIR_NAME_FORCE = $DIR_NAME_FORCE"
echo " HOUSEKEEP_ENABLED = $HOUSEKEEP_ENABLED"
echo " HOUSEKEEP_DAYS = $HOUSEKEEP_DAYS"
echo " VIDEO_SEGMENT_TIME = $VIDEO_SEGMENT_TIME"
echo " VIDEO_FORMAT = $VIDEO_FORMAT"
echo "Container Parameters:"
echo " Stream URL = $streamURL"
echo " Folder Name = $dirName"

# exit if no stream parameter has been passed
if [ -z "${streamURL// }" ]; then
    echo "Please pass a stream url as parameter to the container. Exiting..."
    exit 1
fi

DIR_NAME_FORCE=$(getBoolean "$DIR_NAME_FORCE")
HOUSEKEEP_ENABLED=$(getBoolean "$HOUSEKEEP_ENABLED")

# make sure the folder name is not empty
if [ -z "${dirName// }" ]; then
    dirName=$(getRandomName)
fi

# generate a new folder name if one with the same name exists
while [ "$DIR_NAME_FORCE" = false ] && [ -d "$dir/$dirName" ]; do
    dirName=$(getRandomName)
done

dir="$dir/$dirName"
mkdir -p "$dir"

if [ $(getLowercase "$VIDEO_FORMAT") == "mkv" ]; then
    fileExtension="mkv"
fi

# remove old recordings
if [ "$HOUSEKEEP_ENABLED" = true ]; then
    cronDailyPath="/etc/periodic/daily"
    
    echo "#!/bin/sh" > "$cronDailyPath/delete-old-streams"
    echo "find $dir -type f -mtime +$HOUSEKEEP_DAYS -delete" >> "$cronDailyPath/delete-old-streams"

    chmod +x "$cronDailyPath/delete-old-streams"

    crond
fi

echo "Saving stream in \"$dirName\""

# start recording with ffmpeg
ffmpeg -rtsp_transport tcp \
    -y \
    -stimeout 1000000 \
    -i "$streamURL" \
    -c copy \
    -f segment \
    -segment_time "$VIDEO_SEGMENT_TIME" \
    -segment_atclocktime 1 \
    -strftime 1 \
    "$dir"/%Y-%m-%d_%H-%M-%S."$fileExtension" \
    -loglevel panic