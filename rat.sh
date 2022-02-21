#!/bin/bash

set -e

export RECORDINGS_BUCKET="digitalsanctum-recordings"
export TRANSCRIPTIONS_BUCKET="digitalsanctum-transcriptions"

function list-recordings() {
  aws s3api list-objects --bucket ${RECORDINGS_BUCKET}
}

function list-transcriptions() {
  aws s3api list-objects --bucket ${TRANSCRIPTIONS_BUCKET}
}

function download-transcription() {
  if [[ $# -ne 1 ]] ; then
    echo "usage: download-transcription [TRANSCRIPTION_ID]"
    return 1
  fi
  echo "Downloading transcription $1"
  aws s3api get-object --bucket ${TRANSCRIPTIONS_BUCKET} --key $1 $1
}

function view-transcription() {
  if [[ $# -ne 1 ]] ; then
    echo "usage: view-transcription [TRANSCRIPTION_FILE]"
    return 1
  fi
  echo
  cat $1 | jq -r '.results.transcripts[].transcript'
  echo
}

function get-transcription() {
  if [[ $# -ne 1 ]] ; then
    echo "usage: get-transcription [RECORDING_ID]"
    return 1
  fi
}

function transcribe-recording() {
  if [[ $# -ne 1 ]] ; then
    echo "usage: transcribe-recording [RECORDING_NAME]"
    return 1
  fi
  echo "Starting to transcribe '$1'"
  aws transcribe start-transcription-job \
    --transcription-job-name "$1" \
    --language-code 'en-US' \
    --media-format 'wav' \
    --media "{\"MediaFileUri\": \"s3://${RECORDINGS_BUCKET}/$1\"}" \
    --output-bucket-name '${TRANSCRIPTIONS_BUCKET}'
}

function upload-recording() {
  if [[ $# -ne 1 ]] ; then
    echo "usage: upload-recording [RECORDING_FILE]"
    return 1
  fi
  echo "Uploading recording: $1"
  aws s3 cp $1 s3://${RECORDINGS_BUCKET}
}

# Play recording
function play() {
  # given a filename, play it
  if [[ $# -ne 1 ]] ; then
    echo "usage: rp [FILENAME]"
    return 1
  fi
  if [ -f "$1" ]; then
    echo "Playing $1"
    aplay "$1"
  else
    echo "File not found: $1"
  fi
}

# Record voice (one channel)
function record() {
  local filename="$1"
  echo "Recording to: $filename"
  arecord -i -f dat -c 1 ${filename} --process-id-file=pid
}

function transcription-status() {
  if [[ $# -ne 1 ]] ; then
    echo "usage: transcription-status [TRANSCRIPTION_ID]"
    return 1
  fi
  aws transcribe get-transcription-job --transcription-job-name $1
}

function wait-for-completion() {
  local status=""
  while [ "$status" != "COMPLETED" ]
  do
    sleep 2
    status="$(aws transcribe get-transcription-job --transcription-job-name $1 | jq -r '.TranscriptionJob.TranscriptionJobStatus')"
    echo "Transcription Status: $status"
  done
}

function rat() {
  # trap ctrl-c
  local timestamp=$(date +%Y%m%d%H%M%S)
  local filename="recording-$timestamp.wav"
  trap "upload-recording ${filename}; transcribe-recording ${filename}; wait-for-completion ${filename}; download-transcription ${filename}.json; view-transcription ${filename}.json" SIGINT
  record $filename
}

rat
