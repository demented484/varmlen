import { browser } from "$app/environment";

export type LogLevel = "warn" | "info" | "debug";

interface Persisted {
  autostart: boolean;
  killswitch: boolean;
  allowLan: boolean;
  logLevel: LogLevel;
}

const KEY = "aegisvpn.settings";
const DEFAULTS: Persisted = {
  autostart: false,
  killswitch: true,
  allowLan: true,
  logLevel: "warn",
};

function load(): Persisted {
  if (!browser) return DEFAULTS;
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return DEFAULTS;
    const parsed = JSON.parse(raw) as Partial<Persisted>;
    return {
      autostart: !!parsed.autostart,
      killswitch: parsed.killswitch ?? DEFAULTS.killswitch,
      allowLan: parsed.allowLan ?? DEFAULTS.allowLan,
      logLevel: ["warn", "info", "debug"].includes(parsed.logLevel as string)
        ? (parsed.logLevel as LogLevel)
        : DEFAULTS.logLevel,
    };
  } catch {
    return DEFAULTS;
  }
}

const _initialSettings = load();

class SettingsStore {
  autostart = $state(_initialSettings.autostart);
  killswitch = $state(_initialSettings.killswitch);
  allowLan = $state(_initialSettings.allowLan);
  logLevel = $state<LogLevel>(_initialSettings.logLevel);

  private persist(): void {
    if (!browser) return;
    localStorage.setItem(
      KEY,
      JSON.stringify({
        autostart: this.autostart,
        killswitch: this.killswitch,
        allowLan: this.allowLan,
        logLevel: this.logLevel,
      }),
    );
  }

  setAutostart(v: boolean): void { this.autostart = v; this.persist(); }
  setKillswitch(v: boolean): void { this.killswitch = v; this.persist(); }
  setAllowLan(v: boolean): void { this.allowLan = v; this.persist(); }
  setLogLevel(v: LogLevel): void { this.logLevel = v; this.persist(); }
}

export const settings = new SettingsStore();
