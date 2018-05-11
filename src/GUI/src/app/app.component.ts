import { Component, OnInit, ViewChild } from '@angular/core';
import { DataService } from './services/data.service';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { PsResponse } from './interfaces/psresponse.interface';
import * as appConfig from './_config/appConfig';
import { HTTPErrorHandler } from './models/httpErrorHandler.model';
import { Router } from '@angular/router';
import * as serverResponseTestJSON from './_config/serverResponseTest';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.less']
})
export class AppComponent implements OnInit {
  isConnectionReady = false;
  settingsJSON: Settings.SettingObject;
  popupMessage = '';
  popupTitle = '';

  constructor(private dataservice: DataService, private router: Router, private spinnerService: Ng4LoadingSpinnerService){
    console.log('AppComponent constructor');
  }

  ngOnInit(){
    console.log('AppComponent ngOnInit');
    if (!appConfig.default.devmode){
      this.setConnectionReady();
    }else{
      this.downloadSettings();
    }
  }

  setConnectionReady(): void{
    this.spinnerService.show();
    this.isConnectionReady = true;
        this.downloadSettings();
        console.log('Server is running...');
        this.spinnerService.hide();
        this.router.navigate(['/project/default']);
    // this.dataservice.checkServer().subscribe(
    //   (x) => {
    //     this.isConnectionReady = true;
    //     this.downloadSettings();
    //     console.log('Server is running...');
    //     this.spinnerService.hide();
    //     this.router.navigate(['/project/default']);
    //   },
    //   (x: HTTPErrorHandler) => {
    //     this.isConnectionReady = false;
    //     this.popupMessage = x.uiMessage;
    //     this.popupTitle = 'Server error!';
    //     this.spinnerService.hide();
    //     this.router.navigate(['/']);
    //     $('#mainModal').fadeIn();
    //     console.log(x.uiMessage);
    //   }
    // )
  }

  downloadSettings(): void{
    this.dataservice.downloadConfigJSON().subscribe(
      (x: PsResponse) => {
        this.dataservice.onlineMode = true;
        this.settingsJSON = x.Output;
        console.log(`[app.component.ts]::Settings JSON from Server: ${JSON.stringify(x.Output)}`); // ${JSON.stringify(x.Output)}
        this.dataservice.SettingsObjectSetter(this.settingsJSON);
      },
      (x: HTTPErrorHandler) => {
        this.dataservice.onlineMode = false;
        console.log("Settings JSON from Local.");
        const demoOutput = serverResponseTestJSON.default;
        this.dataservice.SettingsObjectSetter(demoOutput);
        if (appConfig.default.devmode){
          this.router.navigate(['/project/default']);
        }
      }
    );
  }

  closeWindowModal(){
    $('#mainModal').fadeOut();
    this.setConnectionReady();
  }

  delay(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
