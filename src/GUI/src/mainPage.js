const electron = require('electron');
const _ = require('lodash');
const underscore = require('underscore');
const $ = require('jquery');
const powershell = require('node-powershell');
const ipc = electron.ipcRenderer;
const Sortable = require('sortablejs');
const fs = require('fs');
const Noty = require('noty');
const settingsLoader = require('./modules/settingLoader');
const runner = require("./modules/runner");

const statusArray = [
    {type:"complete",class:"successProcess"},
    {type:"error",class:"errorProcess"},
    {type:"progress",class:"progressProcess"},
    {type:"end",class:"-----"}
];

let appSettings = settingsLoader("GUISettings.json");
let defaultSettings = settingsLoader(appSettings.defaultInstallJSON);
let localSettings = settingsLoader(appSettings.localInstallJSON);
//let mySettings = settingsLoader(appSettings.myInstallJSON);

let settingsFilePath =  __dirname+appSettings.settingsPath+appSettings.defaultInstallJSON;
let localsettingsFilePath =  __dirname+appSettings.settingsPath+appSettings.localInstallJSON;
let settingsRealyJSON, defaultSettingsMemo, localSettingsMemo;
let loadedMode = appSettings.defaultProcessName;

settingsFileIdDependency = {
    "settingslocal":localsettingsFilePath,
    "settingsdefault":settingsFilePath
};

$(document).ready( () => {
    //ipc.send('process-start','test');
    settingsInit(defaultSettings,"jsonsettingsdefault");
    settingsInit(localSettings,"jsonsettingslocal");
    //console.log("mySettings:",mySettings);
    $('#runfullprocessbtn').attr("data-processname",loadedMode);

    var el = document.getElementById('items');
    var sortable =new Sortable(el,{
        sort:true,
        animation: 150,
        handle:".dragMark"
    });

    $("input[id*='toggle-']").bootstrapToggle();
});

// Run only one process
$(document).on('click','.runbtn',function (e) {
    e.preventDefault()
    var $this = $(this);
    var processname = this.dataset.processname;
    var l = Ladda.create(this);
    l.start();
    //Run(this.dataset.processname,l);

    runner(__dirname+"/PSscripts/Scripts",[this.dataset])
    .then(v => {
        console.log("End process");
        new Noty({
            type:'success',
            text: `${processname} succesfuly!`,
            theme:'metroui',
            progressBar:false,
            layout:'bottomRight',
            timeout:2000,
            animation: {
                open : 'animated fadeInRight',
                close: 'animated fadeOutRight'
            }
        }).show();
        l.stop();
    })
    .catch(err => {
        console.error("[HIBA]::"+err.msg);
        l.stop();
    })
})

// Run full mode process (e.g. fullinstall)
$(document).on('click','#runfullprocessbtn',function (e) {
    e.preventDefault();
    DisableRunBtns(true);
    ResetStatus();
    var l = Ladda.create(this);
    l.start();
    let scriptsArray = [];
    //let scriptsArray = ["script1","script2","script3"];
    $("#items li").each(function(index,item){
        var isEnabled = $(this).find("input").prop("checked");
        if(isEnabled){
            let runobj = {};
            runobj.processname = $(item).find("div.processname").text();
            runobj.processid = $(item).attr("id");
            scriptsArray.push(runobj);
        }
    })
    console.log(scriptsArray);
    runner(__dirname+"/PSscripts/Scripts",scriptsArray)
    .then(v => {
        console.log("End full procvess mode");
        $("#InfoModal").modal();
        DisableRunBtns(false);
        l.stop();
    })
    .catch(err => {
        console.error("[HIBA]::"+err.msg);
        DisableRunBtns(false);
        l.stop();
    })
})

SaveSettingsJSON = function(settingtype){
    let newSewArray = {};
    var counter = 0;
    let sections = $("#"+settingtype+" div[class*='section']");
    sections.each(function(index,item){
        var title = $(item).find("h3").text();
        newSewArray[title] = {};
        $(this).find("div.repeater"+counter).find("input[data-save='true']").each(function(index,item){
            var key = item.dataset.key;
            var datatype = item.dataset.type;
            if(datatype === "array"){
                newSewArray[title][key] = item.value.split(",");
            }else{
                newSewArray[title][key] = item.value;
            }
            
        })
        counter++;
    })
    var settingsPath = settingsFileIdDependency[settingtype];
    var rawcurrentJson = fs.readFileSync(settingsPath,"utf8");
    var saveJSON = JSON.stringify(newSewArray);
    var currentJSON = JSON.parse(rawcurrentJson);
    // if(currentJSON.Modes){
    //     let parsejson = JSON.parse(saveJSON);
    //     parsejson.Modes = currentJSON.Modes;
    //     saveJSON = JSON.stringify(parsejson);
    // }
    fs.writeFile(settingsPath, saveJSON, 'utf8', function(err,data){
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
        let generateID = IDgenerate();
        $('#processOrder ul').append(`
        <li class="list-group-item" id="${generateID}">
            <div class="row fullwidth">
                <div class="col-xs-2 col-sm-1 col-md-2 col-lg-1 text-center dragMark"><i class="fa fa-sort" aria-hidden="true"></i></div>
                <div class="col-xs-5 col-sm-6 col-md-6 col-lg-6 processname">${item}</div>
                <div class="col-xs-5 col-sm-4 col-md-4 col-lg-5 text-right">
                    <div class="row">
                        <div class="col-xs-7">
                            <span class="preloadertext"></span>
                        </div>
                        <div class="col-xs-3">
                            <button type="button" class="btn btn-success btn-sm runbtn ladda-button onlyRunBtn RunBTN" 
                            data-processname="${item}" data-style="zoom-out">
                                <span class="ladda-label">Run</span>
                            </button>
                            <i class="fa fa-times errorProcess hidden" aria-hidden="true"></i>
                            <i class="fa fa-check successProcess hidden" aria-hidden="true"></i>
                            <i class="fa fa-circle-o-notch fa-spin fa-3x fa-fw progressProcess hidden"></i>
                        </div>
                            <div class="col-xs-1">
                            <input id="toggle-${generateID}" type="checkbox" checked data-toggle="toggle" 
                            data-size="mini" data-on="On" data-off="Off" data-onstyle="primary" data-offstyle="danger">
                        </div>
                </div>
            </div>
        </li>`);
    })
    $("input[id*='toggle-']").bootstrapToggle();
}

DisableRunBtns = function(status){
    $("#items button.onlyRunBtn").each(function(index,item){
        if(status){
            if(!$(item).prop("disabled")){
                $(item).attr("disabled", true);
            }
        }else{
            if($(item).prop("disabled")){
                $(item).attr("disabled", false);
            }
        }
    })
}

IDgenerate = function(){
    function s4() {
          return Math.floor((1 + Math.random()) * 0x10000)
            .toString(16)
            .substring(1);
    }
    return s4() + s4() + s4();
}

ResetStatus = function(){
    // Reset status....
    $("#items li").each(function(index,item){
        var processID = $(item).attr("id");
        ChangeStatus(processID,"end",true);
        ShowMsgToProcess(processID,"");
    });
    $("#InfoModal").modal("hide");
}

ChangeStatus = function(id,type){
    let btn = $("#"+id).find(".onlyRunBtn");
    if(!btn.hasClass("hidden")){
        btn.addClass("hidden");
    }
    if(type === "end"){
        if(btn.hasClass("hidden")){
            btn.removeClass("hidden");
        }
    }
    for(var i=0;i<statusArray.length;i++){
        var icon = $("#"+id).find(`.${statusArray[i].class}`);
        if(statusArray[i].type === type){
            if(icon.hasClass("hidden")){
                icon.removeClass("hidden");
            }
        }
        else
        {
            if(!icon.hasClass("hidden")){
                icon.addClass("hidden");
            }
        }
    }
}

ShowMsgToProcess = function(id,msg){
    let msgPlace = $("#"+id).find(".preloadertext");
    msgPlace.text(msg);
}

LoadSettingsFromJSON = function(tools,type){
    let counter = 0;
    $.each(tools,function(key,value){
        if($.type(value)==="object"){
            $("#"+type).append(`
            <div class="section${counter}">
                <div class="col-xs-12 col-md-6 col-md-offset-3 title">
                    <h3>${key}</h3>
                    <hr>
                </div>
                <div class="col-xs-12 repeater${counter}"></div>
            </div> `);
            $.each(value,function(subkey,subvalue){
                var arrayMark = "";
                if($.type(subvalue) === "array"){
                    arrayMark = "[ array ]";
                }
                $("#"+type+" div.repeater"+counter).append(
                    `<div class="form-group row">
                        <label for="example-text-input" class="col-xs-12 col-md-6 col-md-offset-3 col-form-label">${subkey} ${arrayMark}</label>
                        <div class="col-xs-12 col-md-6 col-md-offset-3">
                          <input class="form-control" data-type="${$.type(subvalue)}" data-save="true" data-key="${subkey}"
                          type="text" value="${subvalue}" id="example-text-input">
                        </div>
                    </div>`);
            });
            counter++;
        }
    })
}

settingsInit = function(param,type){
    console.log("[settingsInit]:");
    //console.log(param.Modes);
    if(type === "jsonsettingsdefault"){
        settingsRealyJSON = param;
        if(typeof param.Modes[loadedMode] === "undefined"){
            loadedMode = underscore.first(underscore.keys(param.Modes), 1);
        }
        let modeobj = {};
        modeobj.array = param.Modes[loadedMode];
        modeobj.name = loadedMode;
        ChangeInstallProcess(modeobj);
        LoadSettingsFromJSON(param,type);
        // if(typeof param.Tools != "undefined"){
        //     LoadSettingsFromJSON(param.Tools,type);
        // }
    }else if(type === "jsonsettingslocal"){
        localSettingsMemo = param;
        LoadSettingsFromJSON(param,type);
        // if(typeof param.Tools != "undefined"){
        //     LoadSettingsFromJSON(param,type);
        // }
    }

}

// --------------------------------
    // ------- IPC Handlers -----------
    // --------------------------------
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

    // Process status handlers
    ipc.on('process-success',(evt,param)=>{
        console.log("[SUCCESS]:",param.processname)
        ChangeStatus(param.processid,"complete",true);
        ShowMsgToProcess(param.processid,"Finished successfully!");
    })

    ipc.on('process-error',(evt,param)=>{
        console.log("[ERROR]:",param.processname)
        ChangeStatus(param.processid,"error",true);
        let errmsg = "";
        if(typeof param.errobj["GUImsg"] != 'undefined'){
            errmsg = param.errobj.GUImsg;
        }
        ShowMsgToProcess(param.processid,errmsg);
    })

    ipc.on('process-loadingstart',(event,param)=>{
        console.log("[LOADING]:",param.processname)
        ChangeStatus(param.processid,"progress",true);
        ShowMsgToProcess(param.processid,"Processing...");
    })