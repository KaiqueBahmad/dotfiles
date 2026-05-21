#!/bin/bash

# Spotify scrolling status script for tmux
# Requires: spotify-cli or osascript (macOS) or dbus (Linux)

# Configuration
MAX_LENGTH=40          # Maximum display length
SCROLL_SPEED=2         # Characters to shift per update
PREFIX="♫ "           # Icon prefix

# Get current track info based on OS
get_spotify_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS using AppleScript
        state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
        if [[ "$state" == "playing" ]]; then
            artist=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)
            track=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)
            echo "▶ $artist - $track"
        elif [[ "$state" == "paused" ]]; then
            artist=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)
            track=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)
            echo "⏸ $artist - $track"
        fi
    else
        # Linux using dbus
        status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus' 2>/dev/null | grep -oP '(?<=string ").*(?=")')
        
        if [[ "$status" == "Playing" ]] || [[ "$status" == "Paused" ]]; then
            metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata' 2>/dev/null)
            artist=$(echo "$metadata" | grep -A 1 "xesam:artist" | tail -n 1 | grep -oP '(?<=string ").*(?=")')
            track=$(echo "$metadata" | grep -A 1 "xesam:title" | tail -n 1 | grep -oP '(?<=string ").*(?=")')
            
            if [[ "$status" == "Playing" ]]; then
                echo "▶ $artist - $track"
            else
                echo "⏸ $artist - $track"
            fi
        fi
    fi
}

# Create or get scroll position file
SCROLL_POS_FILE="/tmp/tmux_spotify_scroll_pos"
[[ ! -f "$SCROLL_POS_FILE" ]] && echo "0" > "$SCROLL_POS_FILE"

# Get current info
info=$(get_spotify_info)

if [[ -z "$info" ]]; then
    echo "${PREFIX}Not playing"
    exit 0
fi

full_text="${PREFIX}${info}"
text_length=${#full_text}

# If text is shorter than max length, just display it
if [[ $text_length -le $MAX_LENGTH ]]; then
    echo "$full_text"
    echo "0" > "$SCROLL_POS_FILE"
    exit 0
fi

# Read current scroll position
scroll_pos=$(cat "$SCROLL_POS_FILE")

# Add padding to create seamless loop
padded_text="${full_text}     ${full_text}"

# Extract visible portion
visible_text="${padded_text:$scroll_pos:$MAX_LENGTH}"

# Update scroll position
new_pos=$((scroll_pos + SCROLL_SPEED))
if [[ $new_pos -ge $text_length ]]; then
    new_pos=0
fi

echo "$new_pos" > "$SCROLL_POS_FILE"
echo "$visible_text"
