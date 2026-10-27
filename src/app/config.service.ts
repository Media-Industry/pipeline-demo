import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

export interface AppConfig {
  environmentName: string;
  apiUrl: string;
}

@Injectable({ providedIn: 'root' })
export class ConfigService {
  private http = inject(HttpClient);
  private config!: AppConfig;

  async load(): Promise<void> {
    // ?v= stops the browser from caching an old config
    this.config = await firstValueFrom(
      this.http.get<AppConfig>(`/config.json?v=${Date.now()}`)
    );
  }

  get value(): AppConfig {
    return this.config;
  }
}