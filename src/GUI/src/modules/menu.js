const electron = require('electron');
const loadJsonFile = require('load-json-file');
const {app} = electron;
let settingsFilePath = __dirname+'/PSscripts/Scripts/Settings/project-default.json';
const settings = require('./settings/settings');

function loadModes(settingsFilePath){
    console.log("settingsFilePath load start.");
    return new Promise((resolve, reject) => {
        loadJsonFile(settingsFilePath).then(json => {
            resolve(json);
        });
    });

}

function menuTemplate(mainWindow,settingsFilePath) {

    return new Promise((resolve, reject) => {
        loadJsonFile(settingsFilePath).then(json => {
            let modesMenu = [];
            console.log("SETT",settings.properties.defaultProcessName);
            for(var attributename in json.Modes){
                let menuObj = {};
                let tempArray = json.Modes[attributename];
                menuObj.label = attributename;
                menuObj.type = 'radio';
                menuObj.checked = false;
                if(attributename === settings.properties.defaultProcessName){
                    menuObj.checked = true;
                }
                menuObj.click = ()=>{
                    var modeObj = {};
                    modeObj.array = tempArray;
                    modeObj.name = menuObj.label;
                    mainWindow.webContents.send('modeChange',modeObj)
                }
                modesMenu.push(menuObj);
            }
            //console.log(modesMenu);
            const menuTemplate = [
                {
                    label: "Menu",
                    submenu:[{
                        label: "Refresh",
                        click: _=>{
                            console.log('Click the submenu1')
                        },
                        role:'reload'
                    },{
                        type: 'separator'
                    },
                    {
                        label:'Devtools',
                        role:'toggledevtools'
                    },
                    {
                        label:'Testmenu',
                        click:_=>{
                            mainWindow.webContents.send('testevent',"Event start menuitem")
                        }
                    },
                    {
                        label: 'Exit',
                        click: _=>{
                            app.quit()
                        },
                        accelerator:"ctrl+m"
                    }]
                },
                {
                    label: "Modes",
                    submenu:modesMenu
                }
            ]
            
            resolve(menuTemplate);
        });
    });
}

module.exports = {
    loadModes:loadModes,
    menuTemplate:menuTemplate
}
