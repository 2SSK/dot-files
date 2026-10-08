---
description: Download YouTube video transcript
---

Download the transcript for the YouTube video at $1 using yt-dlp.

Run this command:
```
yt-dlp --write-subs --write-auto-subs --skip-download --convert-subs srt "$1"
```

Then convert the .srt file to plain text and display the transcript content.
