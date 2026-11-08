#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly ROOT="${OSS_REFERENCES_ROOT:-$HOME/code/others/oss-references}"
readonly CONSUMER_ROOTS="${OSS_REFERENCES_CONSUMER_ROOTS:-$HOME/code}"
