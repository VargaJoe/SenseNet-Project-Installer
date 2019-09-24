import { Component, OnInit } from '@angular/core';
import { ProjectService } from '../../services/project.service';
import { Project } from '../../interfaces/project.interface';
import { DataService } from '../../services/data.service';

@Component({
  selector: 'app-navigation',
  templateUrl: './navigation.component.html',
  styleUrls: ['./navigation.component.less']
})
export class NavigationComponent implements OnInit {
  allproject: Array<Project>;

  constructor(private projectService: ProjectService, private dataservice: DataService) { }
  get isOnline(){
    return this.dataservice.onlineMode;
  }
  ngOnInit() {
    this.allproject = this.projectService.projects;
  }

  selectProject(project){
    console.log(project.displayname);
  }

}
