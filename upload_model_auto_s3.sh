#!/bin/bash

# Check if one argument is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <huggingface_model_url>"
  exit 1
fi

# Check if AWS CLI is installed
if ! [ -x /usr/bin/aws ]; then
    echo "AWS CLI not found. Installing..."
    TEMP_AWS_DIR=$(mktemp -d)
    AWS_ZIP="awscli-exe-linux-x86_64.zip"
    AWS_ZIP_URL="https://awscli.amazonaws.com/$AWS_ZIP"

    # Download AWS CLI
    curl -L "$AWS_ZIP_URL" -o "$TEMP_AWS_DIR/$AWS_ZIP"

    if [ $? -ne 0 ]; then
        echo "Error downloading AWS CLI."
        rm -rf "$TEMP_AWS_DIR"
        exit 1
    fi

    # Unzip and install AWS CLI
    unzip "$TEMP_AWS_DIR/$AWS_ZIP" -d "$TEMP_AWS_DIR"

    if [ $? -ne 0 ]; then
        echo "Error unzipping AWS CLI."
        rm -rf "$TEMP_AWS_DIR"
        exit 1
    fi

    sudo "$TEMP_AWS_DIR/aws/install" --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

    if [ $? -ne 0 ]; then
        echo "Error installing AWS CLI."
        rm -rf "$TEMP_AWS_DIR"
        exit 1
    fi

    echo "AWS CLI installed successfully."
    rm -rf "$TEMP_AWS_DIR"

fi

# Check if AWS credentials are configured
if ! aws configure list &>/dev/null; then
    echo "AWS credentials not configured. Please run 'aws configure' to set up your credentials."
    exit 1
fi

SOURCE_URL="$1"
MODEL_FILENAME=$(basename "$SOURCE_URL")
S3_BUCKET_NAME=$(echo "$MODEL_FILENAME" | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/^-*//;s/-*$//' | tr '[:upper:]' '[:lower:]') # Create buc
ket name from filename
DEST_S3_URI="s3://$S3_BUCKET_NAME"
TEMP_DIR=./tmp
MODEL_PATH="$TEMP_DIR/$MODEL_FILENAME"
SPLIT_PREFIX="$TEMP_DIR/split_"
SPLIT_SIZE="2G"

mkdir "$TEMP_DIR"

# Download the model file
echo "Downloading model from $SOURCE_URL to $MODEL_PATH..."
curl -L "$SOURCE_URL" -o "$MODEL_PATH"

if [ $? -ne 0 ]; then
    echo "Error downloading model."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Split the model file
echo "Splitting model file into $SPLIT_SIZE parts..."
split -b "$SPLIT_SIZE" "$MODEL_PATH" "$SPLIT_PREFIX"

if [ $? -ne 0 ]; then
    echo "Error splitting model file."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Create the S3 bucket if it doesn't exist
echo "Creating S3 bucket: $S3_BUCKET_NAME (if it doesn't exist)"
aws s3api create-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null || true # 2>/dev/null suppresses "BucketAlreadyOwnedByYou" errors

# Upload the split files to S3
echo "Uploading split files to $DEST_S3_URI..."
for file in "$SPLIT_PREFIX"*; do
    filename=$(basename "$file")
    s3_dest_path="$DEST_S3_URI/$filename"
    echo "Uploading $filename to $s3_dest_path"
    aws s3 cp "$file" "$s3_dest_path"

    if [ $? -ne 0 ]; then
        echo "Error uploading $filename."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
done

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "Model successfully split and uploaded to $DEST_S3_URI."

exit 0
