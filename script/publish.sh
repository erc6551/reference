#!/usr/bin/env bash

cp README.md src/README.md
cd src
npm publish
rm README.md
cd ..
