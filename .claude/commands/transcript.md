---
description: Download YouTube video transcript
---
Download the transcript for the YouTube video at $ARGUMENTS using yt-dlp:

yt-dlp --write-subs --write-auto-subs --skip-download --convert-subs srt "$ARGUMENTS"

Then convert the .srt file to plain text and display the transcript content.
