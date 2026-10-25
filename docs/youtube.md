# YouTube

Record, then edit in Kdenlive (the opt-in **creator** layer: `packages/install.sh creator`).

1. **Rain on** (optional): `music "Rainy Night"` in the scratchpad (`$mod+minus`) loops slow rain
   with distant thunder; the player's volume sets how loud it is in the video.
2. **Record:** F12 opens the capture panel; **Shift+R / W / S** records a region, a window or the
   screen on the GPU, with the desktop's sound (not the mic), into `~/Videos/Recordings`. Hide the
   scratchpad first if you record the whole screen.
3. **Edit in Kdenlive:** drop the recording on V1; **Shift+R** cuts at the playhead, select a piece
   and **Delete**, right-click a gap for *Remove space*; *Project → Add Title Clip* for text.
4. **Subtitles:** once, *Settings → Configure Kdenlive → Speech to Text*, choose **Whisper** and let
   it install. Then *Project → Subtitles → Speech Recognition*; fix words on the subtitle track.
5. **Export:** *Project → Render*, **MP4-H264/AAC**.

`~/Music/Rainy Night/` is one 30-minute track made with ffmpeg (no fades, so it loops without a seam;
nothing to license). Keep it well under your voice.
