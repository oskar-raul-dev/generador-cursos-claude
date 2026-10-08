import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  template: `
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
  `
})
export class AppComponent {
  title = 'phase11-angular8-min';
  message = 'Angular 8 corriendo dentro del contenedor legacy';
}
