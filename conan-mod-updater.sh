#!/usr/bin/env bash
set -Eeuo pipefail

CONAN_ID="440900"
CONAN_SERVER_APP_ID="443030"

BASE_PATH="/home/ubuntu/conan_exiles"
CONFIG_PATH="$BASE_PATH/ConanSandbox/Saved/Config/LinuxServer"
MOD_PATH="$BASE_PATH/ConanSandbox/Mods"
MODLIST_PATH="$MOD_PATH/modlist.txt"
TEMP_MODLIST_PATH="$MOD_PATH/modlist.txt.tmp"
LOG_PATH="$MOD_PATH/conan-mod-updater.log"
LOCK_FILE="$MOD_PATH/conan-mod-updater.lock"

STEAMCMD="$HOME/.local/share/Steam/steamcmd/steamcmd.sh"
SERVER_SETTINGS="$CONFIG_PATH/ServerSettings.ini"

TMUX_SESSION="conan"
SERVER_BIN="$BASE_PATH/ConanSandbox/Binaries/Linux/ConanSandboxServer-Linux-Shipping"
SERVER_CMD="$SERVER_BIN ConanSandbox"

PRUNE=false
SERVER_WAS_RUNNING=false
SERVER_STOPPED_BY_SCRIPT=false
LOCK_RELEASED=false

usage() {
    cat <<EOF
Usage: ./conan-mod-updater.sh [options]

Options:
  --prune        Remove downloaded workshop mods no longer listed in ServerModList
  -h, --help     Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prune)
            PRUNE=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            usage
            exit 1
            ;;
    esac

    shift
done

mkdir -p "$MOD_PATH"

exec > >(tee -a "$LOG_PATH") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

server_running() {
    tmux has-session -t "$TMUX_SESSION" 2>/dev/null
}

release_lock() {
    if [[ "$LOCK_RELEASED" == false ]]; then
        flock -u 9 2>/dev/null || true
        exec 9>&- 2>/dev/null || true
        LOCK_RELEASED=true
    fi
}

start_server() {
    if server_running; then
        log "Conan server is already running in tmux session: $TMUX_SESSION"
        return 0
    fi

    if [[ ! -x "$SERVER_BIN" ]]; then
        log "ERROR: Missing or non-executable server binary: $SERVER_BIN"
        exit 1
    fi

    log "Starting Conan server in tmux session: $TMUX_SESSION"

    # Release the updater lock before starting tmux.
    # Otherwise tmux/Conan can inherit the lock and block future updates.
    release_lock

    tmux new-session -d -s "$TMUX_SESSION" -c "$BASE_PATH" "$SERVER_CMD"

    log "Conan Exiles server started."
    log "Attach with: tmux attach -t $TMUX_SESSION"
}

stop_server() {
    if ! server_running; then
        log "Conan server is not currently running."
        return 0
    fi

    log "Stopping Conan server tmux session: $TMUX_SESSION"

    SERVER_STOPPED_BY_SCRIPT=true

    log "Sending first Ctrl-C..."
    tmux send-keys -t "$TMUX_SESSION" C-c

    sleep 10

    if ! server_running; then
        log "Conan server stopped after first Ctrl-C."
        return 0
    fi

    log "Sending second Ctrl-C..."
    tmux send-keys -t "$TMUX_SESSION" C-c

    for _ in {1..60}; do
        if ! server_running; then
            log "Conan server stopped."
            return 0
        fi

        sleep 1
    done

    log "WARNING: Server did not stop after second Ctrl-C and 60 seconds. Killing tmux session."
    tmux kill-session -t "$TMUX_SESSION"
}

cleanup() {
    rm -f "$TEMP_MODLIST_PATH"
}

on_error() {
    log "ERROR: Conan mod updater failed."

    if [[ "$SERVER_WAS_RUNNING" == true && "$SERVER_STOPPED_BY_SCRIPT" == true ]]; then
        log "Server was running before the update. Attempting to start it again."
        start_server || true
    fi

    release_lock
}

trap cleanup EXIT
trap on_error ERR

exec 9>"$LOCK_FILE"

if ! flock -n 9; then
    log "ERROR: Another Conan update is already running."
    log "If no updater is running, remove stale lock file: $LOCK_FILE"
    exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
    log "ERROR: tmux is not installed or not in PATH."
    exit 1
fi

if [[ ! -f "$SERVER_SETTINGS" ]]; then
    log "ERROR: Missing config file: $SERVER_SETTINGS"
    exit 1
fi

if [[ ! -x "$STEAMCMD" ]]; then
    log "ERROR: Missing or non-executable SteamCMD: $STEAMCMD"
    exit 1
fi

if server_running; then
    SERVER_WAS_RUNNING=true
    log "Conan server is currently running."
    stop_server
else
    log "Conan server is not currently running."
fi

log "Updating Conan Exiles dedicated server app $CONAN_SERVER_APP_ID..."

"$STEAMCMD" \
    +force_install_dir "$BASE_PATH" \
    +login anonymous \
    +@sSteamCmdForcePlatformType Linux \
    +app_update "$CONAN_SERVER_APP_ID" validate \
    +quit

server_mod_list="$(
    awk -F= '
        {
            key=$1
            gsub(/^[ \t]+|[ \t]+$/, "", key)

            if (tolower(key) == "servermodlist") {
                sub(/^[^=]*=/, "")
                gsub(/\r/, "")
                print
                exit
            }
        }
    ' "$SERVER_SETTINGS"
)"

mapfile -t MODS < <(
    printf '%s\n' "$server_mod_list" |
    awk '
        {
            while (match($0, /[0-9]+/)) {
                id = substr($0, RSTART, RLENGTH)

                if (!seen[id]++) {
                    print id
                }

                $0 = substr($0, RSTART + RLENGTH)
            }
        }
    '
)

backup_modlist() {
    if [[ -f "$MODLIST_PATH" ]]; then
        cp -a "$MODLIST_PATH" "$MODLIST_PATH.bak"
        log "Backup created: $MODLIST_PATH.bak"
    fi
}

finish_modlist() {
    backup_modlist
    mv "$TEMP_MODLIST_PATH" "$MODLIST_PATH"
    log "Updated: $MODLIST_PATH"
}

if [[ -z "$server_mod_list" || "${#MODS[@]}" -eq 0 ]]; then
    log "No valid mods found in ServerModList."
    : > "$TEMP_MODLIST_PATH"
    finish_modlist

    log "Ensuring Conan server is running after update."
    start_server

    log "Done."
    exit 0
fi

log "Found ${#MODS[@]} unique mod ID(s)."

: > "$TEMP_MODLIST_PATH"

pak_count=0
warning_count=0

for mod_id in "${MODS[@]}"; do
    log "Downloading mod $mod_id..."

    "$STEAMCMD" \
        +force_install_dir "$MOD_PATH" \
        +login anonymous \
        +@sSteamCmdForcePlatformType Linux \
        +workshop_download_item "$CONAN_ID" "$mod_id" \
        +quit

    mod_dir="$MOD_PATH/steamapps/workshop/content/$CONAN_ID/$mod_id"

    if [[ ! -d "$mod_dir" ]]; then
        log "WARNING: Mod directory not found for mod $mod_id: $mod_dir"
        ((warning_count+=1))
        continue
    fi

    mapfile -t pak_files < <(
        find "$mod_dir" -maxdepth 1 -type f -name '*.pak' | sort
    )

    if [[ "${#pak_files[@]}" -eq 0 ]]; then
        log "WARNING: No .pak file found for mod $mod_id"
        ((warning_count+=1))
        continue
    fi

    if [[ "${#pak_files[@]}" -gt 1 ]]; then
        log "WARNING: Multiple .pak files found for mod $mod_id"
        ((warning_count+=1))
    fi

    for pak_file in "${pak_files[@]}"; do
        if [[ "$pak_file" != "$MOD_PATH/"* ]]; then
            log "ERROR: Pak path is outside MOD_PATH: $pak_file"
            exit 1
        fi

        relative_path="${pak_file#"$MOD_PATH/"}"

        echo "$relative_path" >> "$TEMP_MODLIST_PATH"
        log "Added: $relative_path"

        ((pak_count+=1))
    done
done

if [[ "$pak_count" -eq 0 ]]; then
    log "ERROR: No .pak files were added. Leaving existing modlist unchanged."
    exit 1
fi

if [[ "$PRUNE" == true ]]; then
    content_dir="$MOD_PATH/steamapps/workshop/content/$CONAN_ID"

    if [[ -d "$content_dir" ]]; then
        declare -A wanted_mods=()

        for mod_id in "${MODS[@]}"; do
            wanted_mods["$mod_id"]=1
        done

        shopt -s nullglob

        for existing_mod_dir in "$content_dir"/*; do
            [[ -d "$existing_mod_dir" ]] || continue

            existing_mod_id="${existing_mod_dir##*/}"

            if [[ -z "${wanted_mods[$existing_mod_id]+x}" ]]; then
                log "Pruning stale mod: $existing_mod_id"
                rm -rf -- "$existing_mod_dir"
            fi
        done

        shopt -u nullglob
    fi
fi

finish_modlist

log "Ensuring Conan server is running after update."
start_server

log "Downloaded mods: ${#MODS[@]}"
log "Pak files added: $pak_count"
log "Warnings: $warning_count"
log "Done."
