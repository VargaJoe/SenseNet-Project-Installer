import { Step } from './step.interface';

export interface Plot{
    name: String;
    command: String;
    displayname?: String;
    isRunning?: boolean;
    steps: Array<Step>;
    status?: Step;
    msg?: String;
}
