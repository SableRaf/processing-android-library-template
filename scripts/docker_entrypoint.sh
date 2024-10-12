#!/bin/sh

# This file is used to build the project inside a Docker container.
# The Dockerfile copies the project files to the container and then runs this script.
# The script runs the Gradle build and copies the build outputs back to 
# the /output directory in the local filesystem.

# Exit immediately if a command exits with a non-zero status
set -e

# Run the Gradle build
./gradlew clean dist

# Copy the build outputs to /output
cp -r distribution /output/distribution
cp -r library /output/library
cp -r build/libs /output/libs

echo "Build artifacts have been copied to /output."