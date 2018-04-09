const electron = require('electron');
const path = require('path');
const underscore = require('underscore');
const os = require('os');
const loadJsonFile = require('load-json-file');
const fs = require('fs');

// Modules:
const settingsLoader = require('./modules/settingLoader');
const menu = require('./modules/menu');


// Electron tools
const app = electron.app;
const Browser = electron.BrowserWindow;
const ipc = electron.ipcMain;
const Menu = electron.Menu;
const Tray = electron.Tray;

let mainWindow;
let counter = 5;
let proc_fullinstall;
let appSettings = settingsLoader("GUISettings.json");
let settingsFilePath =  __dirname+appSettings.settingsPath+appSettings.defaultInstallJSON;
let settingsJSON;
let windowMenu;

app.on('ready', _=> {
    console.log("App is ready.");
    console.log(appSettings);

    mainWindow = new Browser({
        height:900,
        width:1300,
        resizable: true,
        icon: __dirname + '/logo.ico'
    });

    menu.menuTemplate(mainWindow,settingsFilePath).then(template =>{
        windowMenu = Menu.buildFromTemplate(template);
        Menu.setApplicationMenu(windowMenu);
        
        mainWindow.loadURL(`file://${__dirname}/mainPage.html`);
        
        //mainWindow.webContents.toggleDevTools();
    
        mainWindow.on('closed', _ => {
            console.log("App is closed.");
            mainWindow = null
        });
    })
    
    
})

ipc.on('pasrun-start',(event, arg)=>{
    console.log("[pasrun-start]::"+arg);
})

ipc.on('pasrun-end',(event, arg)=>{
    console.log("[pasrun-end]::"+arg);
})

// If the process successfuly
ipc.on('pasrun-success',(event, arg)=>{
    console.log("[pasrun-success]::"+JSON.stringify(arg));
    event.sender.send('process-success',arg);
})

// If the process error
ipc.on('pasrun-error',(event, arg)=>{
    console.log("[pasrun-err]::"+JSON.stringify(arg));
    event.sender.send('process-error',arg);
})

// If the process start..
ipc.on('pasrun-loadingstart',(event,arg)=>{
    console.log("[pasrun-loadingstart]::"+JSON.stringify(arg));
    event.sender.send('process-loadingstart',arg);
})

ipc.on('process-start',(event, arg)=>{
    console.log("Process start...");
    loadJsonFile(settingsFilePath).then(json => {
        //console.log("JSON ok...");
        settingsJSON = json;
        event.sender.send('process-response',json);
    });
})

ipc.on('change-mode',(event,arg)=>{
    let index = 0;
    for(let i=0;i<windowMenu.items[1].submenu.items.length;i++){
        if(windowMenu.items[1].submenu.items[i].label === arg.name){
            index = i;
        }
    }
    windowMenu.items[1].submenu.items[index].checked = true;
})