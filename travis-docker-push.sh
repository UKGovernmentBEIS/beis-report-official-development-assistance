#!/bin/bash
TAG="${TRAVIS_BUILD_NUMBER}-${TRAVIS_COMMIT}"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
docker build --target release -t "thedxw/beis-report-official-development-assistance:$TAG" .
docker push "thedxw/beis-report-official-development-assistance:$TAG"
