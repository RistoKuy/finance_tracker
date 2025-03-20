#!/bin/bash

# Source icon file
SOURCE_ICON="android/app/src/main/res/app_icon.png"

# Create required directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Generate icons at different densities
convert $SOURCE_ICON -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert $SOURCE_ICON -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert $SOURCE_ICON -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert $SOURCE_ICON -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert $SOURCE_ICON -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

echo "Icon generation complete."
