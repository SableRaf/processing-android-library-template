#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# Default target directory
TARGET_DIR=""

# Check if the sketchbook argument is provided
SKETCHBOOK_COPY=false

# List of important files and directories we don't want to overwrite
IMPORTANT_FILES=(
    "Dockerfile"
    "README.md"
    "gradle"
    "gradlew"
    "gradlew.bat"
    "settings.gradle"
    "build.gradle"
    "app"
    "library"
    "processing"
    "scripts"
)

# Parse the input arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -sketchbook) SKETCHBOOK_COPY=true ;; # Enable sketchbook copying
        -target) TARGET_DIR="$2"; shift ;; # Set the target directory for output
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Function to install Docker for Ubuntu/Debian-based systems
install_docker_linux() {
    echo "Docker CLI is not installed. Installing Docker on Linux..."
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Function to check if Docker is installed and install it if necessary
install_docker_macos() {
    echo "Docker CLI is not installed. Installing Docker..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install --cask docker
    echo "Please open Docker Desktop manually to start the Docker daemon."
    open /Applications/Docker.app
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            install_docker_linux
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            install_docker_macos
        else
            echo "Unsupported operating system. Please install Docker manually."
            exit 1
        fi
    else
        echo "Docker CLI is already installed."
    fi
}

# Check if Docker is running and start the daemon if necessary
start_docker_linux() {
    if ! sudo systemctl is-active --quiet docker; then
        echo "Starting Docker daemon..."
        sudo systemctl start docker
    else
        echo "Docker daemon is already running."
    fi
}

start_docker_macos() {
    if ! docker info > /dev/null 2>&1; then
        echo "Starting Docker Desktop..."
        open /Applications/Docker.app
        while ! docker info > /dev/null 2>&1; do
            sleep 5
        done
        echo "Docker Desktop has started."
    else
        echo "Docker is already running."
    fi
}

# Check if Docker is installed
check_docker

# Start Docker daemon based on the operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    start_docker_linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
    start_docker_macos
fi

# Use default output directory if not set
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$(pwd)/output"
fi

# Check if the target directory exists and prompt the user
if [ -d "$TARGET_DIR" ]; then
    read -p "Target directory '$TARGET_DIR' already exists. Do you want to overwrite it? (y/N): " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase using tr
    if [[ "$confirm" != "y" ]]; then
        echo "Operation canceled."
        exit 1
    fi
fi

# Check if the target directory contains important files or directories directly
for file in "${IMPORTANT_FILES[@]}"; do
    if [ -e "$TARGET_DIR/$file" ] && [ ! -d "$TARGET_DIR/$file" ]; then
        echo "Error: Target directory contains important file or directory: $TARGET_DIR/$file"
        echo "Operation canceled to avoid overwriting important files."
        exit 1
    fi
done

# Build the Docker image
echo "Building Docker image..."
docker build -t processing-android-library .

# Run the Docker container and copy the build outputs to the /processing directory (mounted as /mnt_processing)
echo "Running Docker container..."
docker run --rm -v "$TARGET_DIR:/output" processing-android-library

echo "Docker container ran successfully."

# Optionally copy distribution files to the sketchbook if -sketchbook argument was provided
if [ "$SKETCHBOOK_COPY" = true ]; then
    ./scripts/copy_to_sketchbook.sh -source "$TARGET_DIR"
fi

# Add the target directory to .gitignore if it's not already listed
if ! grep -q "^$TARGET_DIR$" .gitignore && ! grep -q "^\./$TARGET_DIR$" .gitignore; then
    # Normalize the target directory by stripping the leading './' or '.' if present
    CLEANED_TARGET_DIR=$(echo "$TARGET_DIR" | sed 's|^\./||' | sed 's|^\.$||')

    # Add './' to the cleaned directory name for consistency in .gitignore
    echo "Adding './$CLEANED_TARGET_DIR' to .gitignore..."

    # Add a new line before appending the target directory to .gitignore
    echo "" >> .gitignore
    echo "./$CLEANED_TARGET_DIR" >> .gitignore

    echo "'./$CLEANED_TARGET_DIR' has been added to .gitignore."
else
    echo "'$TARGET_DIR' is already in .gitignore."
fi