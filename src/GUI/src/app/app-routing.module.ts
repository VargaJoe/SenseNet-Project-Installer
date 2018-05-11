import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { ProjectwrapperComponent } from './components/projectwrapper/projectwrapper.component';
import { SettingsComponent } from './components/settings/settings.component';

const routes: Routes = [
  { path: '', redirectTo: 'project', pathMatch: 'full' },
  { path: 'settings', component: SettingsComponent },
  { path: 'project/:projectname', component: ProjectwrapperComponent },
  { path: "**", redirectTo: '' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
