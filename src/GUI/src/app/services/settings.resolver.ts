import { Injectable } from "@angular/core";
import { DataService } from "./data.service";
import { ActivatedRouteSnapshot, RouterStateSnapshot, Resolve } from "@angular/router";
import { Observable } from 'rxjs/Observable';

@Injectable()
export class SettingsResolver implements Resolve<any>{
    constructor(private dataservice: DataService){}
    resolve(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<any>{
        return this.dataservice.downloadConfigJSON();
    }
}
