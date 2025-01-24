#!/bin/sh

if [ -z "$1" ]; then
    FOLDER=.
else
    FOLDER=$1/
fi

if [ -f "${FOLDER}pom.xml" ]; then
    # Extract the version using grep and sed
    grep -oPm2 "(?<=<version>)[^<]+" "${FOLDER}pom.xml" | tail -n 1 | cut -d'-' -f1
elif [ -f "${FOLDER}package.json" ]; then
    VERSION=$(sed -n 's/.*"version": "\(.*\)",/\1/p' ${FOLDER}package.json)
    echo $VERSION
elif [ -f "${FOLDER}VERSION" ]; then
    # Simply output the content of the VERSION file
    cat "${FOLDER}VERSION"
else
    echo "NA"
fi
