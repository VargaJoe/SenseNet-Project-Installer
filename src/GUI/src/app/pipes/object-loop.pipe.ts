import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
  name: 'objectLoop',
  pure: false
})
export class ObjectLoopPipe implements PipeTransform {

  transform(value: any, args: any[] = null): any {
    if(value != undefined || value != null){
      return Object.keys(value)//.map(key => value[key]);
    }
    
  }

}
