#!/bin/bash

# Fail on errors.
set -e

# Make sure .bashrc is sourced
. /root/.bashrc

# Allow the workdir to be set using an env var.
# Useful for CI pipiles which use docker for their build steps
# and don't allow that much flexibility to mount volumes
WORKDIR=${SRCDIR:-/src}

cd $WORKDIR

if [[ "$1" != "" ]]; then
  if [[ "$1" == "shell" ]]; then
    /bin/bash
  fi
fi

echo "$@"

# shellcheck disable=SC2199
if [[ "$GITHUB_WORKSPACE" != "" ]]; then
  echo "Found github workspace."

  echo "Inside dir: $GITHUB_WORKSPACE"
  echo "Contents: $(ls -al $GITHUB_WORKSPACE)"

  cp -r $GITHUB_WORKSPACE/src/* /src/

  if [ -f "$GITHUB_WORKSPACE/requirements.txt" ]; then
    cp "$GITHUB_WORKSPACE/requirements.txt" .
  fi

    if [ -f "$GITHUB_WORKSPACE/src/requirements.txt" ]; then
    cp "$GITHUB_WORKSPACE/src/requirements.txt" .
  fi

elif [[ "$1" != "" ]]; then
  echo "Github workspace missing, using repo url: $1"
  git clone "$1"

  cd ./*
  echo "Inside dir: $(pwd)"

  mv ./src/* ..

  if [ -f ./requirements.txt ]; then
    mv ./requirements.txt ..
  fi

  cd ..
  echo "Inside dir: $(pwd)"
  echo "Contents: \n$(ls -al)"
fi

if [ -f requirements.txt ]; then
    echo "Installing Project Requirements..."
    pip install -r requirements.txt
fi # [ -f requirements.txt ]

echo "Starting pyinstaller..."

if [ -d ./assets ]; then
  pyinstaller -w -y --workpath /temp --distpath /dist --add-data "assets/;assets/" ./main.py
else
  pyinstaller -w -y --workpath /temp --distpath /dist ./main.py
fi

output_dir="$GITHUB_WORKSPACE/build"
echo "Creating output directory: $output_dir"
mkdir "$output_dir"
ls -al "$output_dir"

echo "Creating temp build directory: /tmp/build"
mkdir /tmp/build
ls -al /tmp/build

echo "Zipping files..."
7z a -tzip "/tmp/build/$INPUT_REPO_NAME.zip" /dist/*

echo "Zipping complete, files:"
ls -al /tmp/build

echo "Moving to github workspace..."
echo "/tmp/build/$INPUT_REPO_NAME.zip --> $output_dir/$INPUT_REPO_NAME.zip"
mv "/tmp/build/$INPUT_REPO_NAME.zip" "$output_dir/$INPUT_REPO_NAME.zip"

echo "Setting permissions..."
chown -R --reference="$GITHUB_WORKSPACE" "$output_dir"
ls -al "$output_dir"

echo "Build complete! See files in $output_dir  (\$GITHUB_WORKSPACE)"
