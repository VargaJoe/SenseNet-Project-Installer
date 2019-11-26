import { Step } from './step.interface';
import { Plot } from './plot.interface';

export interface Project{
    name: String;
    enabled: string;
    displayname: String;
    Steps: Array<Step>;
    Plots: Array<Plot>;
}
