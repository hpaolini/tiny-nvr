I've been using [several scripts to record RTSP streams with ffmpeg,](https://github.com/hpaolini/nvr-scripts) which have worked well over the years, but lately I thought they would be better served in a Docker container. So, here I will show you how to run an [Alpine-based container](https://hub.docker.com/r/hpaolini/tiny-nvr) that captures your camera's live stream, saves the video in segments, and deletes the old ones as time goes on.

First, you'll need to gather the following info from your IP camera:

* Credentials (username and password)
* IP address and port
* RTSP stream URL syntax (for example, some Hikvision cameras follow this syntax _rtsp://username:password@address:port//Streaming/Channels/1_).

If your camera allows it, I recommend enabling TCP for the live stream. UDP is fine for view-only purposes but not saving, since frames are usually dropped to keep up with the packets.

From your terminal, `cd` to the directory where you wish to store the recordings and run the following command. (The first parameter is the RTSP URL, which you should format using the info you have gathered from your camera; while the second parameter is used to name the recording folder--the latter is optional.)

```
docker run \
       -v $(pwd):/usr/data/recordings \
       -e TZ=America/Chicago \
       hpaolini/tiny-nvr \
       rtsp://username:password@address:port//Streaming/Channels/2 \
       my_camera
```

With the default settings, the container creates a folder in the current directory (in the example the folder is named "my\_camera"), saves the stream in 15 minute segments,[^1] and initiates a daily cron job to delete recordings older than 3 days.

I added the following environment variables for additional customization. (Remember, environment variables are changed using the `-e` flag.)


| ENV                | Default       | Description |
| :----------------- | :----         | :------ |
| TZ                 | _Europe/Rome_ | timezone data |
| DIR_NAME_FORCE     | _false_       | use the folder name you pass as parameter during `docker run` even if it exists, otherwise it generates a new folder name |
| HOUSEKEEP_ENABLED  | _true_        | cron job to delete old recordings |
| HOUSEKEEP_DAYS     | _3_           | delete files older than this number of days, if HOUSEKEEP_ENABLED is enabled|
| VIDEO_SEGMENT_TIME | _900_         | seconds of each recording[^1] |
| VIDEO_FORMAT       | _mp4_           | save output as MKV or MP4 file |

Combine this with Kubernetes or Docker Swarm and you've got a simple NVR with a small footprint. Happy hacking!

[^1]: I recommend saving streams in segments of 30 minutes or less. If your camera fails, most likely only your latest recording  would result in a corrupted file, so you still have access to recordings that are closer to the point of failure. Also, the most recent recordings are synced faster to a backup solution.