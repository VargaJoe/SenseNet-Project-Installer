import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { Ng4LoadingSpinnerModule } from 'ng4-loading-spinner';
import {ToastModule} from 'ng2-toastr/ng2-toastr';
import { AppRoutingModule } from './app-routing.module';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import { AppComponent } from './app.component';
import { SettingsComponent } from './components/settings/settings.component';
import { NavigationComponent } from './components/navigation/navigation.component';
import { ProjectwrapperComponent } from './components/projectwrapper/projectwrapper.component';
import { ProjectService } from './services/project.service';
import { DataService } from './services/data.service';

import * as $ from 'jquery';
import { AddHeaderInterceptor } from './services/add-header.interceptor';
import { SettingsResolver } from './services/settings.resolver';
import { ModalwindowComponent } from './components/modalwindow/modalwindow.component';
import { ObjectLoopPipe } from './pipes/object-loop.pipe';

@NgModule({
  declarations: [
    AppComponent,
    ModalwindowComponent,
    NavigationComponent,
    ProjectwrapperComponent,
    SettingsComponent,
    ObjectLoopPipe
  ],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    ToastModule.forRoot(),
    HttpClientModule,
    Ng4LoadingSpinnerModule.forRoot(),
    AppRoutingModule
  ],
  providers: [
    ProjectService,
    {provide: HTTP_INTERCEPTORS, useClass: AddHeaderInterceptor, multi: true},
    DataService
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
