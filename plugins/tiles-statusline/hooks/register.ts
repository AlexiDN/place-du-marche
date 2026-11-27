import type { EngineInterface, Register } from 'claude-code'

// Renders the status line with statusline.sh (bash + jq), fed the same JSON a statusLine command gets.
// Refreshed every second so the cache timer and the live activity move on their own.

// /config entries (manifest userConfig) -> the TSL_* variables statusline.sh reads
const ENV_NAMES: Record<string, string> = {
  style: 'TSL_STYLE', bar: 'TSL_BAR', barWidth: 'TSL_BAR_WIDTH', icons: 'TSL_ICONS',
  showResets: 'TSL_SHOW_RESETS', spacing: 'TSL_SPACING', softRight: 'TSL_SOFT_RIGHT',
  segments: 'TSL_SEGMENTS', segmentsCenter: 'TSL_SEGMENTS_CENTER', segmentsRight: 'TSL_SEGMENTS_RIGHT',
  cacheTtl: 'TSL_CACHE_TTL',
}

let optionEnv: Record<string, string> = {}
let text: string | null = null
let columns = 120
let isRunning = false

/** "claude-opus-5-5[1m]" -> "Opus 5.5"; anything else is shown as given. */
function prettyModel(model: string): string {
  const [, family = '', major, minor] = /^claude-([a-z]+)-(\d+)-(\d+)/i.exec(model) ?? []
  return family ? `${family.charAt(0).toUpperCase()}${family.slice(1)} ${major}.${minor}` : model
}

async function refresh($: EngineInterface): Promise<void> {
  if (isRunning) return
  isRunning = true
  try {
    const [usage, model, info, root] = await Promise.all([
      $.session.usage(), $.session.model(), $.session.info(), $.session.root(),
    ])
    const limit = (kind: string) => {
      const r = usage.rateLimits.find(l => l.kind === kind)
      return r && {
        used_percentage: r.percentUsed,
        resets_at: r.resetsAt ? Math.floor(Date.parse(r.resetsAt) / 1000) : undefined,
      }
    }
    const input = {
      model: { id: model, display_name: prettyModel(model) },
      context_window: { used_percentage: usage.context.percent },
      rate_limits: { five_hour: limit('five_hour'), seven_day: limit('seven_day') },
      transcript_path: info.transcriptPath,
      workspace: { project_dir: root },
    }
    const run = await $.process.run(['bash', `${$.plugin.root}/statusline.sh`], {
      stdin: JSON.stringify(input),
      env: { ...optionEnv, COLUMNS: String(columns) },
      timeoutMs: 5000,
    })
    const out = run.exitCode === 0 ? run.stdout.replace(/\n+$/, '') : null
    if (out !== text) {
      text = out
      $.ui.invalidate('ui.render')
    }
  } finally {
    isRunning = false
  }
}

export const register: Register = (on, options) => {
  optionEnv = {}
  for (const [key, name] of Object.entries(ENV_NAMES)) {
    const value = (options as Record<string, unknown>)[key]
    if (value !== undefined && value !== null) optionEnv[name] = String(value)
  }

  on('session.start', ($, e, next) => {
    $.clock.every(1000, () => refresh($))
    void refresh($)
    return next(e)
  })

  on('ui.render', { component: 'StatusLine' }, ($, e, next) => {
    columns = e.viewport?.columns ?? columns
    return text === null ? next(e) : next({ ...e, props: { ...e.props, text } })
  })
}
