
# docker run -d \
#       -v $(pwd)/data/:/usr/data/recordings \
#       -e TZ=America/Chicago \
#       --name nvr-camera1 \
#       hpaolini/tiny-nvr \
#       rtsp://username:password@address:port//Streaming/Channels/2 \
#       camera1

FROM alpine:3.8

LABEL version="1.0" \
      maintainer="hpaolini"

# TZ                    : set your timezone, lookup your location in the "tz database"
# DIR_NAME_FORCE        : if set to "true", forces the use of the folder name **WARNING: 
#                         FILES COULD BE OVERWRITTEN BY ANOTHER PROCESS IF ENABLED!**
# HOUSEKEEP_ENABLED     : if set to "true", will clean old files
# HOUSEKEEP_DAYS        : files older than these days will be removed
# VIDEO_SEGMENT_TIME    : seconds of each clip - default 5 minutes
# VIDEO_FORMAT          : save output as mkv or mp4 file
#                         (if you get format errors try changing the format)

ENV TZ=Europe/Rome \
    DIR_NAME_FORCE=false \
    HOUSEKEEP_ENABLED=true \
    HOUSEKEEP_DAYS=3 \
    VIDEO_SEGMENT_TIME=900 \
    VIDEO_FORMAT=mp4

ENV BASH_VERSION=4.4.19-r1 \
    TZDATA_VERSION=2018f-r0 \
    FFMPEG_VERSION=3.4.4-r1

RUN apk update \
    && apk add bash=$BASH_VERSION tzdata=$TZDATA_VERSION ffmpeg=$FFMPEG_VERSION \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /usr/data/recordings

COPY ./docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]