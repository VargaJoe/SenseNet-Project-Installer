const fs = require("fs");
const moment = require("moment");

writeLog = function(logfile,msg){
    let premsg = "["+moment().format("YYYY-MM-DD HH:mm:ss")+"]";
    fs.appendFile(`${__dirname}/../logs/${logfile}`,`${premsg}::${msg}\n\t`,function (err) {
        if (err) throw err;
      });
}

module.exports = writeLog;