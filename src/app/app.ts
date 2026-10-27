import { Component, inject } from '@angular/core';
import { ConfigService } from './config.service';

@Component({
  selector: 'app-root',
  template: `<h1>Running in: {{ env }}</h1>`,
})
export class App {
  env = inject(ConfigService).value.environmentName;
}