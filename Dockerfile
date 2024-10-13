# Use a base image with OpenJDK 17 and Gradle 7.6.4
FROM gradle:7.6.4-jdk17 as builder

# Set environment variables for Android SDK
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin

# Install essential tools and download the Android SDK command-line tools
RUN apt-get update && apt-get install -y wget unzip && \
    mkdir -p $ANDROID_HOME/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools && \
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm cmdline-tools.zip && \
    rm -rf /var/lib/apt/lists/*

# Accept Android SDK licenses
RUN yes | sdkmanager --licenses

# Install Android SDK platform tools and API level 33
RUN sdkmanager "platform-tools" "platforms;android-33"

# Set the working directory to /app/processing where your project files are located (in the container)
WORKDIR /app/processing

# Copy the processing and library directories into the Docker container
COPY processing/ /app/processing
COPY library/ /app/library

# Make the Gradle wrapper executable
RUN chmod +x gradlew

# Copy the entrypoint script into the container
COPY scripts/docker_entrypoint.sh /app/scripts/docker_entrypoint.sh
RUN chmod +x /app/scripts/docker_entrypoint.sh

# Set up local.properties with SDK path
RUN echo "sdk.dir=$ANDROID_HOME" > local.properties

# Define the volume for /output
VOLUME /output

# Set the entrypoint to the script
ENTRYPOINT ["/app/scripts/docker_entrypoint.sh"]