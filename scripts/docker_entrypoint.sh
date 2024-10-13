#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Run the Gradle build
/app/processing/gradlew clean dist

# Ensure that the output directories exist
mkdir -p /mnt_processing/distribution
mkdir -p /mnt_processing/library
mkdir -p /mnt_processing/build/libs

# Copy the build outputs to the output directories (mounted as /mnt_processing)
cp -r /app/processing/distribution/* /mnt_processing/distribution
cp -r /app/processing/library/* /mnt_processing/library
cp -r /app/processing/build/libs/* /mnt_processing/build/libs

echo "Build artifacts have been copied to local /processing"