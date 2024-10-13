#!/bin/bash
set -e

# Look up sketchbook.location and library.name from build.properties
sketchbook_location=$(grep "^sketchbook.location=" processing/resources/build.properties | cut -d'=' -f2 | sed "s|\${user.home}|$HOME|")
library_name=$(grep "^library.name=" processing/resources/build.properties | cut -d'=' -f2)

# Check if the sketchbook location exists
if [ -n "$sketchbook_location" ] && [ -d "$sketchbook_location" ]; then
    echo "Sketchbook location: $sketchbook_location"
    echo "Copying build artifacts to $sketchbook_location/libraries/$library_name"
    mkdir -p "$sketchbook_location/libraries/$library_name"
    cp -r processing/distribution/$library_name/* "$sketchbook_location/libraries/$library_name"
    echo "Library '$library_name' successfully copied to $sketchbook_location/libraries/$library_name"
else
    echo "Sketchbook location not found or invalid. Skipping library copy to sketchbook."
fi