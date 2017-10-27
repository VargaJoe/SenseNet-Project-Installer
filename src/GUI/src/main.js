const electron = require('electron');
const path = require('path');
const underscore = require('underscore');
const os = require('os');
const loadJsonFile = require('load-json-file');
const fs = require('fs');

// Modules:
//const psmodule = require('./psmodule');
const settings = require('./modules/settings/settings');
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
let settingsFilePath = __dirname+settings.properties.defaultInstallJSON;
let settingsJSON;
let windowMenu;

app.on('ready', _=> {
    console.log("App is ready.");

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

ipc.on('pasrun-output',(event, arg)=>{
    console.log("[pasrun-output]::"+arg);
})

ipc.on('pasrun-err',(event, arg)=>{
    console.log("[pasrun-err]::"+arg);
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