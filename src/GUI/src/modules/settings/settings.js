const electron = require('electron');
const loadJsonFile = require('load-json-file');
const {app} = electron;

const properties = {};
properties.defaultProcessName = "fullinstall";
properties.defaultInstallJSON = "/PSscripts/Scripts/Settings/project-default.json";

module.exports = {
    properties:properties
}