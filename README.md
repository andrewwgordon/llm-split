# Hugging Face Model to S3 Uploader

This script automates the process of downloading a Hugging Face model, splitting it into 2GB chunks, and uploading those chunks to an AWS S3 bucket.

## Goals and Purpose

The primary goals of this script are:

* **Simplified Model Deployment:** Streamline the process of moving large Hugging Face models to AWS S3 for storage or deployment.
* **Large File Handling:** Address the limitations of uploading large files by splitting them into manageable parts.
* **Automation:** Automate the download, split, and upload process, reducing manual effort.
* **AWS CLI Installation (if needed):** Checks for and installs the AWS CLI if it is not present.
* **AWS Configuration Check:** Checks for existing AWS credentials and configuration.

## Usage Instructions

1.  **Prerequisites:**
    * Ensure you have a Linux-based operating system.
    * Ensure you have internet connectivity.
    * Ensure you have an AWS account and appropriate permissions to create S3 buckets and upload objects.
2.  **Download the Script:**
    * Download the `upload_model_auto_s3.sh` script.
3.  **Make the Script Executable:**
    * Open a terminal and navigate to the directory where you saved the script.
    * Run the command: `chmod +x upload_model_auto_s3.sh`
4.  **Run the Script:**
    * Execute the script with the Hugging Face model URL as an argument:
        ```bash
        ./upload_model_auto_s3.sh <huggingface_model_url>
        ```
        * Replace `<huggingface_model_url>` with the URL of the Hugging Face model you want to upload.
    * Example:
        ```bash
        ./upload_model_auto_s3.sh "[https://huggingface.co/bert-base-uncased/resolve/main/pytorch_model.bin](https://huggingface.co/bert-base-uncased/resolve/main/pytorch_model.bin)"
        ```
5.  **AWS Configuration:**
    * If the AWS CLI is not configured, the script will prompt you to run `aws configure`. Follow the prompts to enter your AWS access key ID, secret access key, default region name, and output format.
6.  **S3 Bucket:**
    * The script will automatically create an S3 bucket based on the model filename (with invalid characters replaced and all lowercase).
    * The bucket will be created in the `eu-west-2` region.
7.  **Upload Progress:**
    * The script will display progress messages as it downloads, splits, and uploads the model.
8.  **Completion:**
    * Upon successful completion, the script will display a message indicating that the model has been uploaded.

## How it Works

1.  **AWS CLI Check and Installation:**
    * The script first checks if the AWS CLI is installed at `/usr/local/bin/aws`.
    * If not found, it downloads and installs the AWS CLI from the official Amazon source.
2.  **AWS Configuration Check:**
    * The script checks if the AWS CLI has been configured with credentials. If not, the script exits.
3.  **Input Handling:**
    * It takes the Hugging Face model URL as a command-line argument.
    * It extracts the model filename from the URL.
4.  **S3 Bucket Name Generation:**
    * It generates a valid S3 bucket name from the model filename by:
        * Replacing invalid characters with hyphens.
        * Removing leading and trailing hyphens.
        * Converting the name to lowercase.
5.  **Model Download:**
    * It downloads the model file from the Hugging Face URL using `curl`.
6.  **File Splitting:**
    * It splits the downloaded model file into 2GB chunks using the `split` command.
7.  **S3 Bucket Creation:**
    * It creates the S3 bucket (if it doesn't already exist) in the `eu-west-2` region using `aws s3api create-bucket`.
8.  **File Upload:**
    * It uploads each split file to the S3 bucket using `aws s3 cp`.
9.  **Cleanup:**
    * It removes the temporary directory and downloaded files.
10. **Completion Message:**
    * The script prints a success message.