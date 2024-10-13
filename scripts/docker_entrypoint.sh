#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# Run the Gradle build with the build cache enabled
/app/processing/gradlew clean dist --build-cache

# Ensure that the output directories exist
mkdir -p /output/distribution
mkdir -p /output/library
mkdir -p /output/build/libs

# Copy the build outputs to the output directories (mounted as /output)
cp -r /app/processing/distribution/* /output/distribution
cp -r /app/processing/library/* /output/library
cp -r /app/processing/build/libs/* /output/build/libs

echo "Build artifacts have been copied to local /processing"