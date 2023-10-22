#!/usr/bin/env bash

cp README.md src/README.md
cd src
npm publish --tag beta
rm README.md
cd ..
