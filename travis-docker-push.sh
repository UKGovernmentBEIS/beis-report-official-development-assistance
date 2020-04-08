#!/bin/bash
TAG="${TRAVIS_BUILD_NUMBER}-${TRAVIS_COMMIT}"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
docker push "thedxw/beis-report-official-development-assistance:$TAG"
