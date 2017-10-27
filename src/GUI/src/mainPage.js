const electron = require('electron');
const _ = require('lodash');
const underscore = require('underscore');
const $ = require('jquery');
const powershell = require('node-powershell');
const ipc = electron.ipcRenderer;
const Sortable = require('sortablejs');
const fs = require('fs');
const Noty = require('noty');
const settings = require("./modules/settings/settings");

let settingsFilePath = __dirname+settings.properties.defaultInstallJSON;
let settingsRealyJSON;
let loadedMode = settings.properties.defaultProcessName;

$(document).on('click','.runbtn',function (e) {
    e.preventDefault()
    var l = Ladda.create(this);
    l.start();
    Run(this.dataset.processname,l);
})

$(document).on('click','#runfullprocessbtn',function (e) {
    e.preventDefault()
    var l = Ladda.create(this);
    l.start();
    Run(this.dataset.processname,l);
})

$(document).ready( () => {
    ipc.send('process-start','test');
    $('#runfullprocessbtn').attr("data-processname",loadedMode);

    var el = document.getElementById('items');
    var sortable =new Sortable(el,{
        sort:true,
        animation: 150,
        handle:".dragMark"
    });
        
});

Run = function(item,spinner){
    console.log("RUN:"+item);
    let ps = new powershell({
        executionPolicy: 'Bypass',
        noProfile: true
    })
    ipc.send('pasrun-start',item);
    
    ps.addCommand(__dirname+"/PSscripts/Scripts/Run",[
            {Mode:item}
    ]);
    ps.invoke()
    .then(output => {
            //$('#output').html(output);
    })
    .catch(err => {
        console.error(err)
        ps.dispose()
    })
    
    ps.on('output', data => {
            //$('#output').html(data);
            ipc.send('pasrun-output',data);
    });
    ps.on('err', data => {
            //$('#output').html(data);
        spinner.stop();
        new Noty({
            type:'error',
            text: 'Script error',
            theme:'metroui',
            progressBar:false,
            layout:'bottomRight',
            timeout:2000,
            animation: {
                open : 'animated fadeInRight',
                close: 'animated fadeOutRight'
            }
        }).show();
        ipc.send('pasrun-err',data);
    });
    ps.on('end', data => {
            console.log("Process ending");
            spinner.stop();
            new Noty({
                type:'success',
                text: 'Successfully completed',
                theme:'metroui',
                progressBar:false,
                layout:'bottomRight',
                timeout:2000,
                animation: {
                    open : 'animated fadeInRight',
                    close: 'animated fadeOutRight'
                }
            }).show();
            ipc.send('pasrun-end',data);
    });
        
    ps.dispose();
    
}

LoadSettingsFromJSON = function(tools){
    $.each(tools,function(key,value){
        $("#jsonsettings").append(
        `<div class="form-group row">
            <label for="example-text-input" class="col-xs-12 col-md-6 col-md-offset-3 col-form-label">${key}</label>
            <div class="col-xs-12 col-md-6 col-md-offset-3">
              <input class="form-control" type="text" value="${value}" id="example-text-input">
            </div>
        </div>`);
    })
}

SaveProcessSeq = function(modetype){
    console.log("Save JSON");
    let newSewArray = [];
    $("#items div.processname").each(function(i,item){
        newSewArray.push(item.innerText);
    });
    console.log(newSewArray);
    if(typeof settingsRealyJSON.Modes[loadedMode] === "undefined"){
        //loadedMode = underscore.first(underscore.keys(settingsRealyJSON.Modes), 1);
        new Noty({
            type:'alert',
            text: 'List updated error!',
            theme:'metroui',
            progressBar:false,
            layout:'bottomRight',
            timeout:2000,
            animation: {
                open : 'animated fadeInRight',
                close: 'animated fadeOutRight'
            }
        }).show();
        return false;
    }
    settingsRealyJSON.Modes[loadedMode] = newSewArray;
    var json = JSON.stringify(settingsRealyJSON);
    fs.writeFile(settingsFilePath, json, 'utf8', function(err,data){
        if (err) throw err;
        console.log("JSON write successfuly!",data);
        new Noty({
            type:'success',
            text: 'List updated succesfuly!',
            theme:'metroui',
            progressBar:false,
            layout:'bottomRight',
            timeout:2000,
            animation: {
                open : 'animated fadeInRight',
                close: 'animated fadeOutRight'
            }
        }).show();
    }); // write it back
}

ChangeInstallProcess = function(modeobj){
    $('#processOrder ul').empty();
    loadedMode = modeobj.name;
    $('#runfullprocessbtn').attr("data-processname",modeobj.name);
    $.each(modeobj.array,function(i,item){
        $('#processOrder ul').append(`<li class="list-group-item">
        <div class="row fullwidth">
            <div class="col-xs-2 col-sm-2 col-md-2 col-lg-1 text-center dragMark"><i class="fa fa-sort" aria-hidden="true"></i></div>
            <div class="col-xs-7 col-sm-7 col-md-7 col-lg-7 processname">${item}</div>
            <div class="col-xs-3 col-sm-3 col-md-3 col-lg-4 text-right">
              <button type="button" class="btn btn-success btn-sm runbtn ladda-button" data-processname="${item}" data-style="expand-left">
              <span class="ladda-label">Run</span>
              </button>
            </div>
        </div>
      </li>`);
    })
}

ipc.on('testevent',(evt,param)=>{
    console.log("[testevent]"+param)
    ipc.send('pasrun-end',param);
})

ipc.on('modeChange',(evt,modeobj)=>{
    console.log("[modeChange]"+JSON.stringify(modeobj));
    ipc.send('change-mode',modeobj);
    ChangeInstallProcess(modeobj);
})

ipc.on('runbtn',(evt,param)=>{
    console.log("[runbtn]")
})

ipc.on('process-response',(evt,param)=>{
    console.log("[process-response]:");
    //console.log(param.Modes);
    if(typeof param.Modes[loadedMode] === "undefined"){
        loadedMode = underscore.first(underscore.keys(param.Modes), 1);
    }
    let modeobj = {};
    modeobj.array = param.Modes[loadedMode];
    modeobj.name = loadedMode;
    ChangeInstallProcess(modeobj);
    
    // Load Tools to settings tab
    if(typeof param.Tools != "undefined"){
        LoadSettingsFromJSON(param.Tools);
    }
    
})