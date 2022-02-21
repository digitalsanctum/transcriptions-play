# Transcriptions Play

Proof of concept using Bash and the AWS CLI to record, upload, transcribe and download transcriptions.


## Prerequisites

Tested on Ubuntu 20.10 only.
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Two buckets created in AWS S3. Defined as variables in the script.
* [arecord](https://linux.die.net/man/1/arecord) installed and configured to work with your microphone.

## Usage

To begin recording, run the following command:
```shell
./rat.sh
```

Ctrl-C to stop recording. 

When the recording is stopped, the following steps occur:

1. The recording file is uploaded to AWS S3.
2. A transcription job is created.
3. The script loops until the transcription job is complete.
4. The transcription job is downloaded from AWS S3 as a JSON file.
5. The JSON file is parsed and the transcription is displayed as text.
