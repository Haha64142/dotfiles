alias home='cd $HOME'
alias winhome='cd $WINHOME'

alias bash_aliases='nvim "$HOME/.bash_aliases"'
alias aliases=bash_aliases
alias als=aliases

alias reload-als='source "$HOME/.bash_aliases"'

alias programs='cd $WINHOME/Documents/Programs'
alias prgms=programs

alias godot='cd $WINHOME/Documents/Programs/Godot'
alias gd=godot

alias game='cd $WINHOME/Documents/Programs/Godot/Game/code && git fetch'

alias aseprite='cd $WINHOME/Documents/Aseprite'
alias ase=aseprite

alias dfu='dfu-flash'
alias gh='github'

y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && cd -- "$cwd"
    rm -f -- "$tmp"
}

localserver() {
    case "$1" in
    "" | "start")
        npm run start --prefix "C:/Users/pwood/Documents/Programs/HTML-Javascript/Local-Server"
        return 0
        ;;
    "-h" | "--help" | "help")
        echo "local-server"
        return 0
        ;;
    "upload")
        local ip="$2"
        local file="$3"
        local filename

        if [ ! -r "$file" ]; then
            echo "Error: invalid file $3"
            return 1
        fi

        filename=$(basename "$file")

        curl -X POST "$ip:80/data" -H "Content-Type: application/octet-stream" -H "x-filename: $filename" --data-binary "@$file"
        return 0
        ;;
    "download")
        local ip="$2"
        local flags=()
        if [ -n "$3" ]; then
            flags+=("-o" "$3")
        fi

        curl "$ip:80/data" "${flags[@]}"
        ;;
    *)
        echo "Invalid option: $1"
        return 1
        ;;
    esac
}

github() {
    case "$1" in
    "" | "-h" | "--help" | "help")
        echo "Usage: github <github_repo>"
        echo ""
        echo "Runs the command: 'git clone \"https://github.com/\$1\" \"\${@:2}\"'"
        return 0
        ;;
    esac

    git clone "https://github.com/$1" "${@:2}"
}

enable_git_ps1() {
    USE_GIT_PS1=1
    if [[ -f "$HOME/git-prompt.sh" && -v USE_GIT_PS1 ]]; then
        source "$HOME/git-completion.bash"
        source "$HOME/git-prompt.sh"

        export GIT_PS1_SHOWDIRTYSTATE=1
        export GIT_PS1_SHOWSTASHSTATE=1
        export GIT_PS1_SHOWUNTRACKEDFILES=1
        export GIT_PS1_SHOWUPSTREAM="auto"
        export GIT_PS1_SHOWCOLORHINTS=1

        PROMPT_COMMAND='__git_ps1 "${ESC}]0;$MSYSTEM:$PWD\007\]\n${GREEN}\u@\h ${MAGENTA}$MSYSTEM ${YELLOW}\w${CYAN}" "${RESET}\n$ "'
    else
        PS1="${ESC}0;$MSYSTEM:$PWD\007\]\n${GREEN}\u@\h ${MAGENTA}$MSYSTEM ${YELLOW}\w${RESET}\n$ "
    fi
}

cd() {
    local add_dir=1

    # Log current directory if it exists
    [ -d "$PWD" ] || add_dir=0

    if [ -f "$DIR_FILE" ] && [ "$add_dir" -eq 1 ]; then
        last_logged=$(tail -n 1 "$DIR_FILE")
        [ "$last_logged" = "$PWD" ] && add_dir=0
    fi

    [ "$add_dir" -eq 1 ] && echo "$PWD" >>"$DIR_FILE"

    # Use built-in cd to actually change directory
    builtin cd "$@" || return

    # Keep only last 20 unique entries (optional cleanup)
    awk 'NR == 1 || $0 != prev { print; prev = $0 }' "$DIR_FILE" | tail -n 20 >"${DIR_FILE}.tmp"
    mv "${DIR_FILE}.tmp" "$DIR_FILE"
}

cdlast() {
    if [ ! -f "$DIR_FILE" ]; then
        echo "No directories saved"
        return 1
    fi

    if [ $# -eq 0 ]; then
        # Default: go to last directory
        local last_dir
        last_dir="$(tail -n 1 "$DIR_FILE")"
        if [ -d "$last_dir" ]; then
            cd "$last_dir"
        else
            echo "Directory no longer exists: $last_dir"
        fi
    elif [ $1 = "list" ]; then
        # List saved directories with line numbers
        tac "$DIR_FILE" | nl -w2 -s'. '
    else
        # Go to a specific directory by number (reversed)
        local line="$1"
        local target
        # Get the Nth line from the bottom (most recent = 1)
        target="$(tac "$DIR_FILE" | sed -n "${line}p")"
        if [ -z "$target" ]; then
            echo "No such saved directory: $line"
            return 1
        elif [ -d "$target" ]; then
            cd "$target"
        else
            echo "Directory no longer exists: $target"
        fi
    fi
}

nginx() {
    case "$1" in
    "help" | "-h" | "--help")
        echo 'Usage: nginx [command]'
        echo ''
        echo 'Commands:'
        echo '  (no command)   same as '\''nginx start'\'''
        echo '  start          start NGINX (restarts if already running)'
        echo '  kill           stop NGINX if it is running'
        echo '  status         show whether NGINX is currently running'
        echo '  help           show this help message'
        echo ''
        echo 'Examples:'
        echo '  nginx          # start or restart NGINX'
        echo '  nginx status   # check if NGINX is running'
        echo '  nginx kill     # stop the NGINX process'

        return 0
        ;;
    "" | "start")
        if nginx status >/dev/null 2>&1; then
            if ! nginx kill; then
                echo "Error terminating NGINX"
                return 1
            fi
        fi

        echo "Starting NGINX"
        pushd /c/nginx/nginx >/dev/null
        start objs/nginx.exe -p .
        popd >/dev/null

        sleep 1
        if nginx status >/dev/null 2>&1; then
            echo "NGINX started successfully"
            return 0
        else
            echo "NGINX failed to start"
            return 1
        fi
        ;;
    "kill")
        if nginx status >/dev/null 2>&1; then
            if /c/nginx/nginx/objs/nginx -p /c/nginx/nginx -s stop >/dev/null 2>&1; then
                echo "NGINX terminated successfully"
                return 0
            else
                echo "Failed to terminate NGINX"
                return 1
            fi
        else
            echo "NGINX is not running"
            return 0
        fi
        ;;
    "status")
        local pidfile="/c/nginx/nginx/logs/nginx.pid"
        if [ -f "$pidfile" ]; then
            pid=$(<"$pidfile")
            if tasklist | grep -q "$pid"; then
                echo "NGINX is running (PID: $(cat $pidfile))"
                return 0
            else
                echo "PID file exists, but process is not running (PID: $pid)"
                return 1
            fi
        else
            echo "NGINX is not running"
            return 1
        fi
        ;;
    *)
        echo "Invalid Option: $1"
        return 1
        ;;
    esac
}

log() {
    if [ "$1" = "-o" ]; then
        shift
        if [ "$1" = "-c" ]; then
            shift
            local count="$1"
            shift
            set -- "HEAD~${count}..HEAD" "$@"
        fi
        git log --oneline "$@"
    else
        git log "$@"
    fi
}

dfu-flash() {
    if [ -z "$1" ]; then
        dfu-flash --help
        return 0
    fi

    if ! command -v dfu-programmer >/dev/null 2>&1; then
        echo "Error: dfu-programmer not found. Please install and add it to PATH"
        return 1
    fi

    local board="atmega16u2"
    local file=""
    local verbose=0

    while [ $# -gt 0 ]; do
        case "$1" in
        "-h" | "--help")
            echo "dfu-flash: A simple wrapper to use dfu-programmer better"
            echo ""
            echo "Usage: dfu-flash [-v <level>] [-d <device>] <file.hex|alias>"
            echo "       dfu-flash [-v <level>] --targets"
            echo ""
            echo "Options:"
            echo "  --help        display this help message"
            echo "  -v <level>    use verbose output at the specified level (1-3)"
            echo "  --targets     list valid targets"
            echo "  -d <device>   set target device (default=atmega16u2)"
            echo ""
            echo "Examples:"
            echo "  dfu-flash blink.hex"
            echo "  dfu-flash -d atmega8u2 keyboard.hex"
            echo "  dfu-flash -v 2 my_alias"
            echo "  dfu-flash --targets"
            echo ""
            echo "Aliases are stored in $DFU_ALIASES_FILE as key=/path/to/file.hex"
            return 0
            ;;
        "-v")
            case "$2" in
            "1")
                verbose=10
                ;;
            "2")
                verbose=100
                ;;
            "3")
                verbose=1000
                ;;
            "")
                echo "Error: No verbosity level specified"
                return 1
                ;;
            *)
                echo "Error: Invalid verbosity level '$2'. Use 1-3"
                return 1
                ;;
            esac
            shift 2
            ;;
        "-d")
            board="$2"
            shift 2
            ;;
        "--targets")
            dfu-programmer --targets
            return 0
            ;;
        *)
            if [ -f "$1" ] && [ -r "$1" ]; then
                file="$1"
                shift
            elif grep -q -F "${1}=" "$DFU_ALIASES_FILE" 2>/dev/null; then
                file=$(grep -F "${1}=" "$DFU_ALIASES_FILE" | cut -d= -f2-)
                shift
            else
                echo "Error: Hex file or alias '$1' not found"
                return 1
            fi
            ;;
        esac
    done

    file="${file/#\$WINHOME/$WINHOME}"
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        echo "Error: No valid file provided"
        return 1
    fi

    echo "[*] Flashing '$file' to $board"

    set -Eo pipefail

    if [ "$verbose" -ne 0 ]; then
        dfu-programmer "$board" erase --debug "$verbose" || { if [ "$?" -ne 5 ]; then
            echo "Error: Failed to erase $board"
            set +Eo pipefail
            return 1
        fi; }
        dfu-programmer "$board" flash "$file" --debug "$verbose" || {
            echo "Error: Failed to flash $file to $board"
            set +Eo pipefail
            return 1
        }
        dfu-programmer "$board" reset --debug "$verbose" || {
            echo "Error: Failed to reset $board"
            set +Eo pipefail
            return 1
        }
    else
        dfu-programmer "$board" erase || { if [ "$?" -ne 5 ]; then
            echo "Error: Failed to erase $board"
            set +Eo pipefail
            return 1
        fi; }
        dfu-programmer "$board" flash "$file" || {
            echo "Error: Failed to flash $file to $board"
            set +Eo pipefail
            return 1
        }
        dfu-programmer "$board" reset || {
            echo "Error: Failed to reset $board"
            set +Eo pipefail
            return 1
        }
    fi

    set +Eo pipefail

    echo "[+] Done"
}

alias curl='curl --ca-native'

alias ls='ls -F --color=auto'
alias grep='grep --color=auto'

alias tree='tree -aC'

alias clr=clear
alias la='ls -a'
alias ll='ls -laF'
