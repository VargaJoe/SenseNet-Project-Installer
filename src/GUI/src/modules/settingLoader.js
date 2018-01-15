const fs = require("fs");

loadSetting = function(settingsfile){
    let rawdata = fs.readFileSync(`${__dirname}/../PSscripts/Scripts/Settings/${settingsfile}`);
    let settingsobject = JSON.parse(rawdata);
    return settingsobject;
}

module.exports = loadSetting;