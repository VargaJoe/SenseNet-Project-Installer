import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import { Injectable } from '@angular/core';

@Injectable()
export class AddHeaderInterceptor implements HttpInterceptor {

    intercept(req: HttpRequest<any>, next: HttpHandler): Observable <HttpEvent<any>> {
        const newRequest: HttpRequest<any> = req.clone({
            setHeaders: {'Content-Type': 'application/json'}
        });

        return next.handle(newRequest);
    }
}
