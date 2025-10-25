#!/bin/bash

# Create Screencasts directory if it doesn't exist
mkdir -p ~/Videos/Screencasts

# Ask for audio recording
read -p "Record audio? (y/n): " audio_choice
if [[ "$audio_choice" == "y" || "$audio_choice" == "Y" ]]; then
    audio_opt="-a default_output"
else
    audio_opt=""
fi

# Always record screen
target="eDP-1"

# Generate output filename with timestamp
output_file="$HOME/Videos/Screencasts/$(date +%Y%m%d_%H%M%S).mp4"

# Run the recording command in background
echo "Starting recording... Press Enter to stop."
gpu-screen-recorder -w $target -f 30 -encoder cpu $audio_opt -o "$output_file" &
pid=$!

# Wait for user to press Enter
read

# Stop the recording
kill $pid

echo "Recording saved to $output_file"