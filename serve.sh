#!/usr/bin/env bash
# Управление локальным сервером сайта
#   ./serve.sh start|stop|status
DIR="$(cd "$(dirname "$0")" && pwd)"
PIDFILE="/tmp/opencode/site.pid"
LOG="/tmp/opencode/serve.log"
PORT=8080

mkdir -p "$(dirname "$PIDFILE")"

running() {
  [ -f "$PIDFILE" ] || return 1
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 1
  [ -n "$p" ] && kill -0 "$p" 2>/dev/null
}

case "${1:-status}" in
  start)
    if running; then echo "уже запущен (pid $(cat "$PIDFILE")) на порту $PORT"; exit 0; fi
    cd "$DIR" || exit 1
    setsid nohup python3 -m http.server "$PORT" --bind 0.0.0.0 \
      > "$LOG" 2>&1 < /dev/null &
    sleep 1
    pgrep -f "http.server $PORT" | head -1 > "$PIDFILE"
    if running; then
      echo "запущен, pid $(cat "$PIDFILE")"
      echo "  http://localhost:$PORT/"
    else
      echo "не удалось запустить, лог: $LOG"; exit 1
    fi
    ;;
  stop)
    if running; then kill "$(cat "$PIDFILE")" 2>/dev/null; rm -f "$PIDFILE"; echo "остановлен"; else echo "не запущен"; fi
    ;;
  restart) "$0" stop; "$0" start ;;
  status)
    if running; then
      echo "работает, pid $(cat "$PIDFILE"), порт $PORT"
      echo "  http://localhost:$PORT/"
      echo "  http://$(hostname -I | awk '{print $1}'):$PORT/  (из других устройств в этой сети)"
    else
      echo "не запущен — старт: $0 start"
    fi
    ;;
  *) echo "использование: $0 start|stop|restart|status"; exit 1 ;;
esac