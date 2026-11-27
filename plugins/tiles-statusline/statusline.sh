#!/usr/bin/env bash
# Claude Code status line.
#   left:   model | context | session (5h) | week | cache timer
#   center: what is running right now (MCP call, skill in use)
#   right:  plugins and MCP servers loaded in the context
# Wraps to two lines when the terminal is too narrow.
# Options come from the mod's /config entries, passed as TSL_* environment variables.
STYLE=${TSL_STYLE:-plain} BAR=${TSL_BAR:-smooth} BAR_WIDTH=${TSL_BAR_WIDTH:-10}
SHOW_RESETS=${TSL_SHOW_RESETS:-true} CACHE_TTL=${TSL_CACHE_TTL:-3600} ICONS=${TSL_ICONS:-true}
SPACING=${TSL_SPACING:-1} SOFT_RIGHT=${TSL_SOFT_RIGHT:-true} SHOW_BUILTIN_MCP=${TSL_SHOW_BUILTIN_MCP:-true}
SEGMENTS=${TSL_SEGMENTS-"model context session week cache"}
SEGMENTS_CENTER=${TSL_SEGMENTS_CENTER-"active"} SEGMENTS_RIGHT=${TSL_SEGMENTS_RIGHT-"plugins mcp"}

in=$(cat)
now=$(date +%s)
IFS=$'\x1f' read -r model model_id ctx five five_reset week week_reset transcript project_dir pc_warm pc_expires pc_ttl < <(jq -r '[
  .model.display_name // "?", (.model.id // "" | sub("\\[.*\\]$"; "")),
  (.context_window.used_percentage // ""),
  (.rate_limits.five_hour.used_percentage // ""), (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // ""), (.rate_limits.seven_day.resets_at // ""),
  (.transcript_path // ""), (.workspace.project_dir // .cwd // ""),
  (.prompt_cache.warm // "" | tostring), (.prompt_cache.expires_at // ""), (.prompt_cache.ttl // "")] | map(tostring) | join("\u001f")' <<<"$in")

# ---- palette (truecolor) ----
fg() { printf '\e[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
bg() { printf '\e[48;2;%d;%d;%dm' "$1" "$2" "$3"; }
R=$'\e[0m' BOLD=$'\e[1m'
TRACK="62 66 88" MUTED="128 134 160" TEXT="205 210 230" DARK="20 22 32" DARK_MUTED="48 50 66"
INK=$DARK INK_MUTED=$DARK_MUTED   # tile text colors, switched to light on soft tiles
ACTIVE_RGB="250 140 200" PLUGINS_RGB="150 200 220" MCP_RGB="180 180 235"
TILES=false; [[ $STYLE == powerline ]] && TILES=true

# Health RGB for a "badness" 0..100: green -> yellow -> orange -> red, interpolated.
heat_rgb() {
  local p=${1%.*} stops=(0 120 210 140 50 235 200 95 75 245 150 80 100 240 90 100) i a b t
  ((p < 0)) && p=0; ((p > 100)) && p=100
  for ((i = 0; i < 12; i += 4)); do
    a=${stops[i]} b=${stops[i + 4]}
    if ((p <= b)); then t=$(( (p - a) * 100 / (b - a) ))
      echo $(( stops[i+1] + (stops[i+5] - stops[i+1]) * t / 100 )) \
           $(( stops[i+2] + (stops[i+6] - stops[i+2]) * t / 100 )) \
           $(( stops[i+3] + (stops[i+7] - stops[i+3]) * t / 100 )); return; fi
  done
}

model_rgb() {
  case ${model_id,,} in
    *opus*) echo 198 160 246 ;; *sonnet*) echo 125 196 228 ;;
    *haiku*) echo 140 220 160 ;; *fable*) echo 245 170 110 ;; *) echo $TEXT ;;
  esac
}

# Text colors: on a colored tile everything is dark; in plain mode values carry the health color.
# Emojis are all default-wide (no variation selector) so the width math stays right.
icon() { [[ $ICONS == true ]] || return
  case $1 in model) printf '🤖 ' ;; context) printf '🧠 ' ;; session) printf '⏳ ' ;; week) printf '📅 ' ;;
             cache) printf '⚡ ' ;; cold) printf '🧊 ' ;; plugins) printf '🧩 ' ;; mcp) printf '🔌 ' ;;
             skill) printf '📘 ' ;; call) printf '🔧 ' ;; esac; }
label() { $TILES && printf '%s%s%s ' "$(fg $INK)$BOLD" "$(icon "$1")" "$1" || printf '%s%s%s ' "$(fg $MUTED)" "$(icon "$1")" "$1"; }
value() { $TILES && printf '%s' "$(fg $INK)$BOLD" || printf '%s' "$(fg ${2:-$(heat_rgb "$1")})$BOLD"; }
# A number: on main tiles, a dark chip with the value in its health color (max contrast); else colored text.
num() { # badness text
  if $TILES && [[ $INK == "$DARK" ]]; then
    # rounded chip: caps drawn in the chip color over the tile background
    printf '%s%s%s%s%s%s%s' "$(fg $DARK)" $'\ue0b6' "$(bg $DARK)$(fg $(heat_rgb "$1"))$BOLD" "$2" \
      "$R$TILE_BG$(fg $DARK)" $'\ue0b4' "$(fg $INK)$BOLD"
  else printf '%s%s' "$(value "$1")" "$2"; fi
}
dim()   { $TILES && printf '%s' "$R$TILE_BG$(fg $INK_MUTED)$BOLD" || printf '%s' "$R$(fg $MUTED)"; }

# ---- optional bar (BAR=none disables it) ----
bar() {
  [[ $BAR == none ]] && return
  local p=${1%.*} c=$2 w=$BAR_WIDTH s="" i eighths full part
  ((p < 0)) && p=0; ((p > 100)) && p=100
  case $BAR in
    dots)  full=$(( (p * w + 50) / 100 ))
           for ((i = 0; i < w; i++)); do ((i < full)) && s+="$c●" || s+="$(fg $TRACK)•"; done ;;
    blocks) full=$(( (p * w + 50) / 100 ))
           for ((i = 0; i < w; i++)); do ((i < full)) && s+="$c■" || s+="$(fg $TRACK)■"; done ;;
    *)     local glyphs=(" " "▏" "▎" "▍" "▌" "▋" "▊" "▉")
           eighths=$(( p * w * 8 / 100 )); full=$(( eighths / 8 )); part=$(( eighths % 8 ))
           s+="$c"; for ((i = 0; i < full; i++)); do s+="█"; done
           if ((full < w)); then
             ((part)) && s+="$(bg $TRACK)${glyphs[part]}$R$TILE_BG" || s+="$(fg $TRACK)█"
             for ((i = full + 1; i < w; i++)); do s+="$(fg $TRACK)█"; done
           fi ;;
  esac
  printf '%s ' "$s"
}

# "2h10m" / "13m" / "3d11h" until an epoch
until_str() { local d=$(( $1 - now )); ((d < 0)) && d=0
  if ((d >= 86400)); then printf '%dd%02dh' $((d / 86400)) $((d % 86400 / 3600))
  elif ((d >= 3600)); then printf '%dh%02dm' $((d / 3600)) $((d % 3600 / 60))
  else printf '%dm' $((d / 60)); fi; }

# "claude-opus-5-5[1m]", "Opus 5.5" -> "opus-5-5": compare models whatever the spelling
norm_model() { local m=${1,,}; m=${m%%\[*}; m=${m#claude-}; m=${m//[^a-z0-9]/-}; echo "$m"; }

# ---- transcript facts (one pass over the tail): last reply, last /compact, live activity ----
cache_left="" last_model="" active=""
if [[ -f $transcript ]]; then
  { IFS=$'\x1f' read -r last_ts last_model compact_ts; active=$(cat); } < <(tail -n 300 "$transcript" | jq -rs '
    (map(select(.type == "assistant" and .message.usage and .message.model != "<synthetic>")) | last) as $a
    | (map(select(.subtype == "compact_boundary")) | last) as $c
    | ([($a.timestamp // ""), ($a.message.model // ""), ($c.timestamp // "")] | join("\u001f")),
      # live activity: inside the current turn (after the last human prompt, not ended yet)
      ( (to_entries | map(select(.value.type == "user" and (.value.isMeta | not)
            and ((.value.message.content | type) == "string"
                 or ([.value.message.content[]? | select(type == "object" and .type == "tool_result")] | length == 0))))
         | last | .key // -1) as $p
        | .[$p + 1:] as $turn
        | if ($turn | map(select(.type == "assistant")) | last | .message.stop_reason) == "end_turn" then empty else
            [$turn[] | select(.type == "user") | .message.content[]? | select(type == "object" and .type == "tool_result") | .tool_use_id] as $done
            | [$turn[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] as $uses
            | ($uses | map(select(.name == "Skill") | "skill\t" + .input.skill) | unique[]),
              ($uses[] | select((.name | startswith("mcp__")) and (.id as $i | $done | index($i) | not))
                | "call\t" + (.name | ltrimstr("mcp__") | sub("^claude_ai_"; "") | sub("__"; " › ")))
          end)' 2>/dev/null)
  if [[ -n $last_ts ]]; then
    t=$(date -d "$last_ts" +%s); cache_left=$(( t + CACHE_TTL - now ))
    # Claude Code reports the real expiry; prefer it when present
    [[ -n $pc_expires ]] && cache_left=$(( pc_expires - now ))
    [[ $pc_ttl == 1h ]] && CACHE_TTL=3600; [[ $pc_ttl == 5m ]] && CACHE_TTL=300
    # cold after a /compact or a model switch, whatever the timer says
    if [[ $pc_warm == false ]] || [[ -n $compact_ts && $(date -d "$compact_ts" +%s) -gt $t ]] \
       || [[ -n $model_id && $(norm_model "$last_model") != "$(norm_model "$model_id")" ]] || ((cache_left < 0)); then
      cache_left=0
    fi
  fi
fi

# MCP servers whose tools are loaded (from the deferred tool records of this session), minus the ones
# that only expose authenticate/complete_authentication: they still need a sign-in, so they are unusable
mcp_servers() {
  [[ -f $transcript ]] || return
  grep -a '"deferred_tools_delta"' "$transcript" | jq -rs --arg builtin "$SHOW_BUILTIN_MCP" '
    reduce (.[] | .attachment) as $d ({}; reduce (($d.addedNames // []) + ($d.surfacedNames // []))[] as $n (.; .[$n] = true)
                                          | reduce ($d.removedNames // [])[] as $n (.; del(.[$n])))
    | keys | map(select(startswith("mcp__")) | ltrimstr("mcp__") | split("__") | {s: .[0], t: .[1]})
    # shortcut: hard-coded list of the servers Claude Code / claude.ai ship, extend it when a new one shows up
    | map(select($builtin == "true" or (.s | IN("ide", "easel", "claude_ai_Claude_Docs") | not)))
    | group_by(.s) | map(select(any(.[]; .t != "authenticate" and .t != "complete_authentication")) | .[0].s
                         | sub("^claude_ai_"; "") | gsub("_"; " "))
    | join(" · ")' 2>/dev/null
}

# Enabled plugins (user, project and local settings)
plugins() {
  local f files=()
  for f in "$HOME/.claude/settings.json" "$project_dir/.claude/settings.json" "$project_dir/.claude/settings.local.json"; do
    [[ -f $f ]] && files+=("$f")
  done
  ((${#files[@]})) || return
  jq -rs 'map(.enabledPlugins // {}) | add | to_entries | map(select(.value == true) | .key | split("@")[0]) | unique | join(" · ")' "${files[@]}" 2>/dev/null
}

# ---- segments: badness_<seg> = tile health, color_<seg> = fixed tile color, seg_<seg> = text (empty = hidden) ----
badness_context() { echo "$ctx"; }
badness_session() { echo "$five"; }
badness_week()    { echo "$week"; }
badness_cache()   { [[ -n $cache_left ]] && echo $(( 100 - cache_left * 100 / CACHE_TTL )); }
color_model()   { model_rgb; }
color_active()  { echo $ACTIVE_RGB; }
color_plugins() { echo $PLUGINS_RGB; }
color_mcp()     { echo $MCP_RGB; }

gauge() { # label pct [reset_epoch]
  [[ -z $2 ]] && { printf '%s--' "$(label "$1")"; return; }
  local c; $TILES && c=$(fg $INK) || c=$(fg $(heat_rgb "$2"))
  printf '%s%s%s' "$(label "$1")" "$(bar "$2" "$c")" "$(num "$2" "${2%.*}%")"
  [[ $SHOW_RESETS == true && -n $3 ]] && printf '%s ↻ %s' "$(dim)" "$(until_str "$3")"
}

seg_model() {
  local i; [[ $ICONS == true ]] && i=$(icon model) || i="◆ "
  $TILES && printf '%s%s%s%s' "$(fg $INK)" "$BOLD" "$i" "$model" || printf '%s%s%s%s' "$(fg $(model_rgb))" "$BOLD" "$i" "$model"
}
seg_context() { gauge context "$ctx"; }
seg_session() { gauge session "$five" "$five_reset"; }
seg_week()    { gauge week "$week" "$week_reset"; }
seg_cache() {
  [[ -z $cache_left ]] && { printf '%s--' "$(label cache)"; return; }
  ((cache_left == 0)) && { printf '%s%scache cold' "$(value 100)" "$( [[ $ICONS == true ]] && icon cold || printf '❄ ')"; return; }
  local b c; b=$(badness_cache); $TILES && c=$(fg $INK) || c=$(fg $(heat_rgb "$b"))
  printf '%s%s%s' "$(label cache)" "$(bar $((100 - b)) "$c")" "$(num "$b" "$(printf '%d:%02d' $((cache_left / 60)) $((cache_left % 60)))")"
}
seg_active() {
  [[ -z $active ]] && return
  local kind name first=1
  while IFS=$'\t' read -r kind name; do
    ((first)) || printf '%s  ' "$(dim)"
    printf '%s%s%s' "$(value 0 "$ACTIVE_RGB")" "$( [[ $ICONS == true ]] && icon "$kind" || printf '%s ' "$kind")" "$name"
    first=0
  done <<<"$active"
}
seg_plugins() { local p; p=$(plugins); [[ -n $p ]] && printf '%s%s' "$(label plugins)" "$(value 0 "$PLUGINS_RGB")$p"; }
seg_mcp()     { local m; m=$(mcp_servers); [[ -n $m ]] && printf '%s%s' "$(label mcp)" "$(value 0 "$MCP_RGB")$m"; }

# ---- render one group of segments ----
render() { # segments [soft]
  local out="" first=1 s txt rgb b padding="  "
  if [[ $2 == true ]]; then INK=$TEXT INK_MUTED=$MUTED padding=" "; else INK=$DARK INK_MUTED=$DARK_MUTED; fi
  for s in $1; do
    declare -F "seg_$s" >/dev/null || continue
    if $TILES; then
      # rounded pill: fixed color, else health color, else gray when there is no data
      if declare -F "color_$s" >/dev/null; then rgb=$("color_$s")
      else b=$(declare -F "badness_$s" >/dev/null && "badness_$s"); [[ -n $b ]] && rgb=$(heat_rgb "$b") || rgb=$MUTED; fi
      [[ $2 == true ]] && rgb=$(blend $rgb)
      TILE_BG=$(bg $rgb)
      txt=$("seg_$s"); [[ -z $txt ]] && continue
      ((first)) || out+=" "
      out+="$R$(fg $rgb)"$''"$TILE_BG$padding$txt$padding$R$(fg $rgb)"$''
    else
      TILE_BG=""
      txt=$("seg_$s"); [[ -z $txt ]] && continue
      ((first)) || out+="$R $(fg $TRACK)│ "
      out+="$R$txt"
    fi
    first=0
  done
  [[ -n $out ]] && printf '%s%s' "$out" "$R"
}

# 35% color over the dark panel: same hue, much quieter (secondary tiles)
blend() { echo $(( $1 * 35 / 100 + 30 * 65 / 100 )) $(( $2 * 35 / 100 + 32 * 65 / 100 )) $(( $3 * 35 / 100 + 46 * 65 / 100 )); }

# visible width: strip escapes, let wc -L apply the terminal width of each char (emojis = 2)
vwidth() { sed 's/\x1b\[[0-9;]*m//g' <<<"$1" | wc -L; }
pad() { (($1 > 0)) && printf '%*s' "$1" ''; }

# ---- layout: left · center · right on one line, else wrap to two lines ----
left=$(render "$SEGMENTS") center=$(render "$SEGMENTS_CENTER") right=$(render "$SEGMENTS_RIGHT" "$SOFT_RIGHT")
wl=$(vwidth "$left") wc=$(vwidth "$center") wr=$(vwidth "$right")
W=$(( ${COLUMNS:-120} - 4 ))   # fixed margin for the UI's own padding, tune if the right edge wraps
gap=2
((wc)) && need=$(( wl + wc + wr + 2 * gap )) || need=$(( wl + wr + gap ))

space() { local i; for ((i = 0; i < SPACING; i++)); do printf '\u2800\n'; done; }
space
if ((need <= W)); then
  if ((wc)); then
    pl=$(( (W - wc) / 2 - wl )); ((pl < gap)) && pl=$gap
    pr=$(( W - wl - pl - wc - wr )); ((pr < gap)) && { pr=$gap; pl=$(( W - wl - wc - wr - gap )); }
    printf '%s%s%s%s%s\n' "$left" "$(pad $pl)" "$center" "$(pad $pr)" "$right"
  else
    printf '%s%s%s\n' "$left" "$(pad $(( W - wl - wr )))" "$right"
  fi
else
  # line 1: left (+ center if it fits), line 2: center otherwise, then right aligned to the edge
  if ((wc && wl + gap + wc <= W)); then
    printf '%s%s%s\n' "$left" "$(pad $gap)" "$center"; center="" wc=0
  else
    printf '%s\n' "$left"
  fi
  space
  if ((wc)); then printf '%s%s%s\n' "$center" "$(pad $(( W - wc - wr )))" "$right"
  else printf '%s%s\n' "$(pad $(( W - wr )))" "$right"; fi
fi
