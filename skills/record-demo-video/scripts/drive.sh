# Source in the work directory: CDP_PORT=<port> source <skill>/scripts/drive.sh
# Smooth, recordable driving on top of agent-browser. Every motion changes the picture on nearly every
# frame: agent-browser's own click glide, `scroll` and `keyboard type` are fast but jump on video.

DEMO_PORT="${CDP_PORT:-${DEMO_PORT:?set CDP_PORT to the app's debugging port when sourcing}}"
ab() { agent-browser --session "${DEMO_SESSION:-demo}" --cdp "$DEMO_PORT" --input-mode human "$@"; }

# take <name>: save the take being recorded (if any) and start takes/<name>.mp4
take() { mkdir -p takes; ab record restart "$PWD/takes/$1.mp4" --cursor >/dev/null && perl -MTime::HiRes=time -e 'printf "%s %.3f\n", $ARGV[0], time' "$1" > takes/.current; }
# mark <label>: log seconds since the current take started to takes/<name>.log, for the edit to cut on
mark() { perl -MTime::HiRes=time -e 'open F, "takes/.current" or die "no take started\n"; ($n, $t) = split " ", <F>; open L, ">>", "takes/$n.log"; printf L "%.2f %s\n", time - $t, $ARGV[0]' "$1"; }

centre() { ab get box "$1" | awk '/^x:/{x=$2}/^y:/{y=$2}/^width:/{w=$2}/^height:/{h=$2}END{printf "%d %d", x+w/2, y+h/2}'; }
# glide @ref: move the pointer to an element along an eased curve; hovering reveals hover-only controls
glide() { local X Y; read X Y <<< "$(centre "$1")"; ab mouse move "$X" "$Y" --human --steps 100 --duration 750 >/dev/null; }
# go @ref: glide, then click
go() { glide "$1"; ab click "$1" >/dev/null; }
# typeit "<text>": type into the focused element at about 20 characters a second
typeit() { local t="$1" i; for ((i = 0; i < ${#t}; i++)); do ab keyboard type "${t:$i:1}" >/dev/null; sleep 0.03; done; }
# glance "<css selector>": scroll an element to the middle of the view, smoothly
glance() { ab eval "document.querySelector($(printf '%s' "$1" | perl -pe 's/\\/\\\\/g; s/"/\\"/g; $_ = "\"$_\""')).scrollIntoView({behavior: 'smooth', block: 'center'})" >/dev/null; }
# ref "<pattern>": the first element ref in a fresh snapshot whose line matches an extended regex
ref() { ab snapshot -i | grep -E "$1" | head -1 | grep -oE 'ref=e[0-9]+' | sed 's/ref=/@/'; }
