#!/usr/bin/env node
// vim: set ft=javascript:

var fs = require("fs");
var path = require("path");
var mustache = require("./vendor/mustache");

var inputFilePath = path.normalize(process.argv[2].toString());
var templateFilePath = path.normalize(process.argv[3].toString());

var inputJson = JSON.parse(fs.readFileSync(inputFilePath));
var template = fs.readFileSync(templateFilePath).toString();

var output = mustache.render(template, inputJson);

process.stdout.write(output);
