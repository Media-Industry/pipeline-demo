import { Component, inject } from '@angular/core';
import { ConfigService } from './config.service';

@Component({
  selector: 'app-root',
  template: `
    @if (env !== 'Production') {
      <div class="ribbon" [class.dev]="env === 'Dev'" [class.uat]="env === 'UAT'">{{ env }}</div>
    }

    <header class="header">
      <span class="logo">SafeHome Insurance</span>
      <a class="btn btn-small" href="#">Log in</a>
    </header>

    <section class="hero">
      <h1>Protect your home in 2 minutes</h1>
      <p>Simple home insurance with a clear price and no paperwork.</p>
      <a class="btn" href="#">Get a quote</a>
    </section>

    <section class="cards">
      <div class="card">
        <h3>Full coverage</h3>
        <p>Fire, water damage and theft, all in one plan.</p>
      </div>
      <div class="card">
        <h3>Fair price</h3>
        <p>From $9 a month. Cancel any time.</p>
      </div>
      <div class="card">
        <h3>24/7 support</h3>
        <p>Real people, ready to help when you need it.</p>
      </div>
    </section>

    <footer class="footer">© 2026 SafeHome Insurance</footer>
  `,
})
export class App {
  env = inject(ConfigService).value.environmentName;
}