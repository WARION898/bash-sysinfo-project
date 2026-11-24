#!/bin/bash

# =================================================================
# СКРИПТ СБОРА СИСТЕМНОЙ ИНФОРМАЦИИ (sysinfo.sh)
# =================================================================

# Красивое оформление (цвета)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color (сброс цвета)

# Функция-помощник для вывода заголовков
print_section() {
    echo -e "\n${BLUE}=================================================${NC}"
    echo -e "${GREEN}>>> $1${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

# 1. Имя хоста и IP-адрес
print_section "ИМЯ ХОСТА И IP-АДРЕС"
echo "Hostname: $(hostname)"
# Берем первый IP из вывода hostname -I (убираем пробелы)
echo "IP Address: $(hostname -I | awk '{print $1}')"

# 2. Аптайм (время работы системы)
print_section "АПТАЙМ (ВРЕМЯ РАБОТЫ)"
# Команда uptime -p выводит в формате "up 2 weeks, 3 days, 4 hours..."
echo "Uptime: $(uptime -p)"

# 3. Список пользователей
print_section "СПИСОК ПОЛЬЗОВАТЕЛЕЙ (Системные аккаунты)"
# Берем имена пользователей из /etc/passwd, у которых UID >= 1000 (обычные юзеры)
# и выводим их через запятую.
users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | paste -sd, -)
echo "Пользователи: $users"

# 4. Топ-5 процессов по памяти
print_section "ТОП-5 ПРОЦЕССОВ ПО ПАМЯТИ"
# ps aux: все процессы
# --sort=-%mem: сортировка по памяти по убыванию
# head -n 6: берем заголовок и первые 5 строк
# awk: выводим только нужные колонки (Имя, PID, %MEM, %CPU)
ps aux --sort=-%mem | head -n 6 | awk '{printf "%-20s %-10s %-10s %-10s\n", $11, $2, $4, $3}' | (read -r header; echo "COMMAND              PID        %MEM       %CPU"; echo "$header"; cat)

# 5. Число неудачных входов из логов
print_section "НЕУДАЧНЫЕ ВХОДЫ (Failed logins)"
# Проверяем наличие лога авторизации. В зависимости от системы он может быть в разных местах.
if [ -f /var/log/auth.log ]; then
    # Для Debian/Kali/Ubuntu
    fail_count=$(grep -c "Failed password" /var/log/auth.log)
    echo "Количество неудачных попыток входа (auth.log): $fail_count"
elif [ -f /var/log/secure ]; then
    # Для RHEL/CentOS/Fedora
    fail_count=$(grep -c "Failed password" /var/log/secure)
    echo "Количество неудачных попыток входа (secure): $fail_count"
else
    # Если логов нет (например, нет прав или другая система), используем journalctl
    fail_count=$(journalctl _COMM=sshd | grep -c "Failed password" 2>/dev/null || echo "0 (логи недоступны)")
    echo "Количество неудачных попыток входа (journalctl): $fail_count"
fi

echo -e "\n${BLUE}=================================================${NC}"
echo -e "${GREEN}Сбор информации завершен!${NC}"
echo -e "${BLUE}=================================================${NC}"
