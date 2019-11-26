import { Component, OnInit } from '@angular/core';
import { DataService } from '../../services/data.service';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.component.html',
  styleUrls: ['./settings.component.less']
})
export class SettingsComponent implements OnInit {
  settings: any;
  jsonsett: any;

  constructor(private dataservice: DataService) {
    console.log('Settings constructor');
    if (this.dataservice.settingsData) {
      console.log('Is settings data');
      // this.settings = this.dataservice.settingsData;
      // for (const key in this.dataservice.settingsData) {
      //   if (this.dataservice.settingsData.hasOwnProperty(key)) {
      //     const element = this.dataservice.settingsData[key];
      //   }
      // }
    } else {
      this.settings = 'Settings not found!';
    }
  }

  get settingsData() {
    return this.settings;
  }

  ngOnInit() {
    console.log('Settings ngOnInit');
    this.dataservice.settingsObjectObserver$.subscribe(
      (x) => {
        this.settings = x;
        console.log('Settings beállítva');
      }
    );

  }

}
