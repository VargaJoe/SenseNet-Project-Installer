import { Component, OnInit, ElementRef, ViewContainerRef } from '@angular/core';
import { ProjectService } from '../../services/project.service';
import { Project } from '../../interfaces/project.interface';
import { PsResponse } from '../../interfaces/psresponse.interface';
import { ActivatedRoute, Params } from '@angular/router';
import { Step } from '../../interfaces/step.interface';
import { Plot } from '../../interfaces/plot.interface';
import { DataService } from '../../services/data.service';
import { ToastsManager } from 'ng2-toastr/ng2-toastr';
import { HTTPErrorHandler } from '../../models/httpErrorHandler.model';
import { concat, merge, concatAll } from 'rxjs/operators';
import { from } from 'rxjs/observable/from';
import { of } from 'rxjs/observable/of';
import { Observable } from 'rxjs/Observable';
import { Subscriber } from 'rxjs/Subscriber';

@Component({
  selector: 'app-projectwrapper',
  templateUrl: './projectwrapper.component.html',
  styleUrls: ['./projectwrapper.component.less']
})
export class ProjectwrapperComponent implements OnInit {
  project: Project;
  plots: Plot[] = [];
  steps: Step[] = [];
  settings: any;
  stepBusy: Boolean = false;
  plotBusy: Boolean = false;
  PlotSubscriber: Observable<PsResponse | HTTPErrorHandler>;

  constructor(private projectService: ProjectService, public toastr: ToastsManager, vcr: ViewContainerRef,
    private route: ActivatedRoute,
    private dataService: DataService) {
      this.toastr.setRootViewContainerRef(vcr);
    }

  ngOnInit() {
    // Subscribe settings
    this.dataService.settingsObjectObserver$.subscribe(
      (x: Settings.SettingObject) => {
        this.settings = x;
        // Steps:
        // tslint:disable-next-line:no-shadowed-variable
        this.settings.Steps.forEach(x => {
          this.steps.push({
            name: x,
            command: x,
            busy: false
          });
        });
        // Plots:
        // tslint:disable-next-line:forin
        for (const plotItem in this.settings.Plots) {
          this.plots.push({
            name: plotItem,
            command: plotItem,
            steps: this.settings.Plots[plotItem],
            isRunning: false
          });
        }
        this.setProjectByRouter();
      }
    );
  }

  setProjectByRouter() {
    this.project = this.settings;
    this.route.params.forEach((params: Params) => {
      if (params['projectname']) {
        // this.project = this.projectService.projects.find(x => x.name === params["projectname"]);
      } else {
        // this.project = this.projectService.projects.find(x => x.name === "default")
      }

    });
  }

  // Run one step
  selectStep(step: Step, StepHTML: ElementRef) {
    if (!step.busy) {
      step.busy = true;
      this.dataService.stepRequest(step).subscribe(
        (x: PsResponse) => {
          console.log(`[Listener]::${x.ExitCode}`);
          step.busy = false;
          if (x.ExitCode === 0) {
            step.status = 'ok';
            step.result = 'Successfuly';
            if (step.command === 'getsettings') {
              console.log(x.Output);
            }
          } else {
            step.status = 'error';
            step.result = 'Failed';
          }
        },
        err => {
          console.log(`Hiba a szerverrel való kommunikáció során: ${err.message}`);
          step.busy = false;
          step.status = 'error';
          if (err.url === null) {
            step.result = `Failed: The Server not respond`;
          } else if (err.ExitCode) {
            step.result = `Failed: (exitcode:${err.ExitCode})`;
          }

        }
      );
    } else {
      console.log(`${step.displayname} foglalt`);
    }

  }

  // Run one Plot
  selectPlot(plot: Plot) {
    console.log(plot.name + '. Start plotRequest');
    if (!plot.isRunning) {
      plot.isRunning = true;
      let counter = 0;
      plot.status = plot.steps[counter];
      plot.steps.forEach(step => {
        // Create Step
        const stepObj = Object.assign(step, {
          name: step,
          command: step,
          displayname: step,
          busy: true,
          status: step.command
        });
        this.dataService.stepRequest(stepObj).subscribe(
          (x: PsResponse) => {
            console.log(`[Listener]${stepObj.command}::${x.ExitCode}`);
            counter++;
            plot.status = plot.steps[counter];
            if (plot.steps.length === counter) {
              console.log('Plot finish');
              plot.isRunning = false;
            }
          },
          err => {
            console.log(`Hiba a szerverrel való kommunikáció során: ${err.message}`);
          }
        );
      });
    }
  }

  selectPlot2(plot: Plot) {
    if (!plot.isRunning && !this.plotBusy) {
      console.log(plot.name + '. is starting..');
      plot.isRunning = true;
      this.plotBusy = true;
      const observableArray: Observable<PsResponse | HTTPErrorHandler>[] = [];
      let counter = 0;
      plot.status = plot.steps[counter];
      plot.msg = `Next step: ${plot.steps[counter + 1]}`;
      plot.steps.forEach(step => {
        // Create Step
        const stepObj = Object.assign(step, {
          name: step,
          command: step,
          displayname: step,
          busy: true,
          status: step.command
        });
        observableArray.push(this.dataService.stepRequest(stepObj));
      });

      from(observableArray).pipe(concatAll())
        .subscribe(
          (x: Observable<PsResponse | HTTPErrorHandler>) => {
            console.log(`[Listener]${JSON.stringify(x)}`);
            counter++;
            plot.status = plot.steps[counter];
            if (counter < plot.steps.length){
              plot.msg = `Next step: ${plot.steps[counter + 1]}`;
            }else{
              plot.msg = ``;
            }
            if (plot.steps.length === counter) {
              console.log('Plot finish');
              plot.isRunning = false;
              this.plotBusy = false;
            }
          },
          err => {
            plot.msg = `Server error!`;
            this.toastr.error("Plot is running...");
            plot.isRunning = false;
            this.plotBusy = false;
            console.log(`Hiba a szerverrel való kommunikáció során: ${err.message}`);
          }
        );
    }else{
      console.log("Plot busy!");
      this.toastr.error("Plot is running...");
    }
  }

}
