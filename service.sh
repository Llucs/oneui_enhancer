#!/system/bin/sh
# One UI Enhancer - Service
# Desenvolvedor: Llucs

MODDIR=${0%/*}
LOGDIR="$MODDIR/logs"
LOG="$LOGDIR/enhancer.log"

# Prepara log
mkdir -p "$LOGDIR"
[ -f "$LOG" ] || touch "$LOG"
chmod 644 "$LOG"

log_msg() {
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$LOG"
}

# 1. Aguarda boot completo (kernel + framework básico)
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

log_msg "Boot completo detectado."

# 2. Aguarda SystemServer estar funcional
log_msg "Aguardando SystemServer..."

COUNT=0
while [ $COUNT -lt 45 ]; do
    if cmd settings get global airplane_mode_on >/dev/null 2>&1; then
        break
    fi
    sleep 2
    COUNT=$((COUNT + 1))
done

log_msg "SystemServer ativo."

# 3. Aguarda usuário desbloquear (SystemUI + NotificationManager prontos)
log_msg "Aguardando usuário desbloquear..."

while [ "$(getprop sys.user.0.ce_available)" != "true" ]; do
    sleep 2
done

# Delay extra necessário na One UI
sleep 5

log_msg "Usuário desbloqueado. Iniciando otimizações."

# 4. Safety check (opcional)
if [ -f "$MODDIR/common/safety.sh" ]; then
    sh "$MODDIR/common/safety.sh"
    if [ $? -ne 0 ]; then
        log_msg "Abortado: Safety check falhou."
        exit 0
    fi
fi

# 5. Execução ordenada dos módulos
for script in cpu.sh gpu.sh io.sh memory.sh background.sh; do
    if [ -f "$MODDIR/common/$script" ]; then
        log_msg "Executando $script"
        sh "$MODDIR/common/$script" >> "$LOG" 2>&1
    fi
done

# 6. Doze / Idle tuning (após sistema totalmente pronto)
cmd settings put global device_idle_constants \
"light_after_inactive_to=30000,light_pre_idle_to=60000,light_idle_to=300000" \
>/dev/null 2>&1

log_msg "Otimizações aplicadas com sucesso."

# 7. Notificação final (agora garantida)
cmd notification post -S bigtext -t "One UI Enhancer" \
"OneUIEnhancer" "Otimizações de Llucs aplicadas com sucesso." \
>/dev/null 2>&1

log_msg "Notificação enviada."