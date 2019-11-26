import { Injectable } from '@angular/core';
import { Project } from '../interfaces/project.interface';
import { Step } from '../interfaces/step.interface';

@Injectable()
export class ProjectService {
  projects: Array<Project>;

  constructor() {
  }


}
