import { Component, Input, Output, EventEmitter } from '@angular/core';

@Component({
  selector: 'app-modalwindow',
  templateUrl: './modalwindow.component.html',
  styleUrls: ['./modalwindow.component.less']
})
export class ModalwindowComponent{
  @Input() body;
  @Input() title;
  @Output() close = new EventEmitter();

  constructor() { }

  closeModal(){
    this.close.emit();
  }

}
