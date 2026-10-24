# YouTube

The tools come in the opt-in **creator** layer: `packages/install.sh creator` (OBS Studio, LosslessCut,
Kdenlive, EasyEffects, and the voiceover and captions tools: Piper and whisper-ctranslate2, pinned, as
uv tools in `~/.local`). Everything runs offline once the voice and the captions model have downloaded.

## A video, start to finish

1. **Start a project:** `yt-new "Kubernetes in 60 seconds"` makes
   `~/Videos/YouTube/<date>-kubernetes-in-60-seconds/` with `raw/` (recordings), `audio/` (voiceover),
   `edit/` (the editor's project), `export/` (the upload), `thumbs/` and `script.txt`.
2. **Write the script** in `script.txt`: a paragraph per beat, a blank line for a pause.
3. **Record** into `raw/`:
   - **OBS Studio** for proper videos: add a *Screen Capture (PipeWire)* source and the screen-sharing
     picker (the capture panel) asks which screen or window; webcam and mic as sources. Encoder:
     *FFmpeg VAAPI H.264* (the Intel GPU: little CPU, a cool laptop).
   - Quick clips: the capture panel (F12), **Shift+R / W / S** to record a region, window or screen.
4. **Voice:**
   - Talking: EasyEffects cleans the mic (below).
   - Not talking: `voiceover script.txt` speaks the script with an offline neural voice into
     `audio/voiceover.wav`, levelled for YouTube (-16 LUFS). `--hindi` for Hindi, `--speed 1.15`
     faster, `--voice NAME` for any [Piper voice](https://rhasspy.github.io/piper-samples).
5. **Edit:** **LosslessCut** to trim recordings without re-encoding (fast, no quality lost);
   **Kdenlive** to put the video, voiceover, music and titles together. Export into `export/`.
6. **Captions:** `captions export/video.mp4` writes `export/video.srt` (Whisper, on the CPU: about
   a third of real time). Upload it to YouTube as subtitles, or import it into Kdenlive to burn
   captions into Shorts. `--hindi` for Hindi; `--model medium` is slower and more accurate.

## A clean mic (EasyEffects)

Once: open EasyEffects, **Input**, add **Noise Reduction** (RNNoise) and **Limiter**, and save the
preset as *voice*. It filters every app's mic from then on (OBS, calls) while EasyEffects runs; the
switch at the top turns it off.

## While recording

The scratchpad (`$mod+Shift+Return` to add, `$mod+minus` to show) holds what you need on hand,
like the script, OBS's controls and notes, in one floating group you can hide from the recording.
Notifications wait while the capture panel records (the shell holds them back); for OBS, turn on
Do Not Disturb in the control center first, so nothing pops into the video.
