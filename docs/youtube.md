# YouTube

Two tools: **gpu-screen-recorder** records (the capture panel, in base) and **Kdenlive** edits and
makes subtitles (the opt-in **creator** layer: `packages/install.sh creator`). The rain plays from
`music`.

## A video, start to finish

1. **Start a project:** `yt-new "Kubernetes in 60 seconds"` makes
   `~/Videos/YouTube/<date>-kubernetes-in-60-seconds/` with `raw/` (recordings), `audio/` (voice,
   music), `edit/` (Kdenlive's project), `export/` (the upload), `thumbs/` and `script.txt`.
2. **Rain on:** in the scratchpad (`$mod+Shift+Return` adds a terminal, `$mod+minus` shows it),
   `music "Rainy Night"` loops the rain; the player's volume sets how loud it is in the video.
3. **Record** with the capture panel (F12): **Shift+R / W / S** records a region, a window or the
   screen, on the GPU, with the desktop's sound (the rain; not the mic). Notifications wait while it
   records. Hide the scratchpad first if you record the whole screen. Recordings land in
   `~/Videos/Recordings`: move them into `raw/`.
4. **Edit in Kdenlive**, its project in `edit/`:
   - Drop the recordings on video track V1 and the voice file (in `audio/`) on A1.
   - Cut: put the playhead on a spot, **Shift+R** cuts the clip there; select the bit you don't want,
     **Delete**. Close the gap: right-click it, *Remove space*.
   - Text on screen: *Project → Add Title Clip*, onto V2.
5. **Subtitles** (Kdenlive's own speech-to-text): once, *Settings → Configure Kdenlive → Speech to
   Text*, choose **Whisper** and let it install its model. Then *Project → Subtitles → Speech
   Recognition* writes them from the voice; fix any words on the subtitle track. They're burned into
   the video on export, or *Subtitles → Export* gives a `.srt` to upload to YouTube instead.
6. **Export:** *Project → Render*, the **MP4-H264/AAC** profile, into `export/`.

## The rain

`~/Music/Rainy Night/` holds one 30-minute track of slow rain with distant thunder now and then (made
with ffmpeg; no fades, so it loops without a seam; nothing to license). `music` plays any folder
on repeat, so it runs as long as you record. Keep it well under your voice: about a third of the
volume you'd listen at.
