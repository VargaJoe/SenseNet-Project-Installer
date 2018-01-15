/**
 *  Powershell scripts running module
 */

const shell = require('node-powershell');
const electron = require('electron');
const Noty = require('noty');
const SNlog = require("./writelog");
const moment = require("moment");
const shareModule = require("./shareModule");
const settingsLoader = require('./settingLoader');
const ipc = electron.ipcRenderer;

let appSettings = settingsLoader("GUISettings.json");

function runPsProcess(scriptfolder,scriptobject,session){
    return new Promise(function(resolve,reject){
        ipc.send('pasrun-loadingstart',scriptobject);
        let ps = new shell({
            executionPolicy: 'Bypass',
            noProfile: true,
            debugMsg: true
        });
        let showoutput = "$False";
        let verbose = "";
        if($("#toggle-showoutput").prop("checked") === true){
            showoutput = "$True"
        }
        if($("#toggle-verbose").prop("checked") === true){
            verbose = "-Verbose"
        }
        let command = `${scriptfolder}/Run.ps1 ${scriptobject.processname} -ShowOutput ${showoutput} ${verbose}`;
        console.log("Command: "+command);
        session.insert({
            row: session.getLength(),
            column: 0
         }, "\n" + `[${moment().format("HH:mm:ss")}] Command: ${command}`);
         
        ps.addCommand(command);
        ps.invoke().then(output => {
            ps.dispose();
            session.insert({
                row: session.getLength(),
                column: 0
             }, "\n" + `[${moment().format("HH:mm:ss")}] Result: ${scriptobject.processname} : ${output}`)
             session.insert({
                row: session.getLength(),
                column: 0
             }, "\n" + "------------------------------------")
            let exitCode = null;
            if(output.trim().indexOf(appSettings.exitcodemagicword)  > -1){
                exitCode = parseInt(output.trim().split(appSettings.exitcodemagicword)[1])
            }
            if(exitCode != null && exitCode != NaN){
                if(exitCode === 0)
                {
                    console.log(scriptobject+" - "+output);
                    ipc.send('pasrun-success',scriptobject);
                    resolve(output);
                }else{
                    let guimsg = "";
                    if(appSettings.exitcodeErrorMsg[exitCode] != undefined){
                        guimsg = appSettings.exitcodeErrorMsg[exitCode];
                    }
                    let errobj = {};
                    errobj.msg=`${scriptobject.processname}.ps1 script error: ${output}`;
                    errobj.GUImsg=guimsg;
                    scriptobject["errobj"] = errobj;
                    SNlog("log.txt",errobj.msg);
                    ipc.send('pasrun-error',scriptobject);
                    resolve(output);
                    //reject(errobj);
                }
            }else{
                let guimsg = "";
                SNlog("log.txt",`Missing exit code (${JSON.stringify(scriptobject)}`);
                console.log("Missing exit code");
                let errobj = {};
                errobj.GUImsg=guimsg;
                scriptobject["errobj"] = errobj;
                errobj.msg=`${scriptobject.processname}.ps1 : Missing exit code`;
                ipc.send('pasrun-error',scriptobject);
                //reject(errobj);
                resolve(errobj);
            }
        }).catch((err) => {
            let errobj = {};
            let guimsg = "";
            errobj.GUImsg=guimsg;
            errobj.msg=`${scriptobject.processname}.ps1 script error: ${err}`;
            SNlog("log.txt",errobj.msg);
            scriptobject["errobj"] = errobj;
            session.insert({
                row: session.getLength(),
                column: 0
             }, "\n" + "----------------Exception--------------------")
             session.insert({
                row: session.getLength(),
                column: 0
             }, "\n" + `[${moment().format("HH:mm:ss")}][ERROR] Error msg: ${errobj.msg}`)
            ipc.send('pasrun-error',scriptobject);
            new Noty({
                type:'error',
                text: `${scriptobject.processname} error`,
                theme:'metroui',
                progressBar:false,
                layout:'topRight',
                timeout:1000,
                animation: {
                    open : 'animated fadeInRight',
                    close: 'animated fadeOutRight'
                }
            }).show();
            //reject(errobj);
            resolve(errobj);
        });
    })
}

runInstall = async function(folder,scriptarray,session){
    let a;
    for(var i=0;i<scriptarray.length;i++){
        if(!shareModule.stopStatus){
            a = await runPsProcess(folder,scriptarray[i],session);
        }else{
            shareModule.stopStatus = false;
            return a;
        }
        
    }
    return a;
    
}

module.exports = runInstall;
