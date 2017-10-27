const electron = require('electron');
module.exports = function () {
    test = "test";
    app = electron.app;

    Run = function(){
        console.log(this.test);
    }
}