#!/usr/bin/env node

const pkg = require("../package.json");
const pkgc = require("../src/package.json");

if (pkg.version !== pkgc.version) {
  console.error("package.json and src/package.json are out of sync");
  process.exit(1);
}
