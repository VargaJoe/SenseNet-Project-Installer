import { Injectable } from '@angular/core';
import { HttpClient, HttpHandler, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { Step } from '../interfaces/step.interface';
import { PsResponse } from '../interfaces/psresponse.interface';
import * as appConfig from '../_config/appConfig';
import { Observable } from 'rxjs/Observable';
import { catchError, mergeAll, merge } from 'rxjs/operators';
import { HTTPErrorHandler } from '../models/httpErrorHandler.model';
import { ErrorObservable } from 'rxjs/observable/ErrorObservable';
import { Subject } from 'rxjs/Subject';
import { forkJoin } from 'rxjs/observable/forkJoin';
import { Plot } from '../interfaces/plot.interface';
import { concat } from 'rxjs/observable/concat';

@Injectable()
export class DataService {
  private settingsObjectSubject = new Subject<any | null>();
  settingsObjectObserver$ = this.settingsObjectSubject.asObservable();
  onlineMode = true;
  settingsData: any;
  constructor(private httpclient: HttpClient) { }

  SettingsObjectSetter(settingsobj: any): void {
    console.log('SettingsObjectSetter:' + JSON.stringify(settingsobj));
    this.settingsObjectSubject.next(settingsobj);
  }

  stepRequest(step: Step): Observable<PsResponse | HTTPErrorHandler> {
    return this.httpclient.post<PsResponse>(
      `${appConfig.default.serverURL}:${appConfig.default.port}`,
      `plot=${step.command}`).pipe(
        catchError(err => {
          return this.httpErrorHandler(err, 0, 'HTTP Powershell listener error');
        })
      );
  }

  downloadConfigJSON(): Observable<PsResponse | HTTPErrorHandler> {
    const getConfigStep = { command: appConfig.default.getSettingsCommand };
    return this.stepRequest(getConfigStep);
  }

  checkServer(): Observable<PsResponse | HTTPErrorHandler> {
    return this.httpclient.get<PsResponse>(`${appConfig.default.serverURL}:${appConfig.default.port}`)
      .pipe(
        catchError(err => {
          return this.httpErrorHandler(err, 1, 'Powershell server error. Please check to running the server.');
        })
      );
  }

  // HTTP error handler
  private httpErrorHandler(error: HttpErrorResponse, errornumber: number, message: string): Observable<HTTPErrorHandler> {
    const dataError = new HTTPErrorHandler();
    dataError.errorObj = error;
    dataError.errorNumber = errornumber;
    dataError.message = error.message;
    dataError.uiMessage = message;
    return ErrorObservable.create(dataError);
  }
}
