#!/bin/bash
# Быстрый скрипт для изменения заголовка таблицы лидеров

echo "=========================================="
echo "🎖️ Изменение заголовка таблицы лидеров"
echo "=========================================="
echo ""
echo "Текущий заголовок:"
echo "🎖️ RedLine Souls Leaderboard (you are all very special) 🎖️"
echo ""
echo "Введите новый заголовок (или нажмите Enter для отмены):"
read -r new_title

if [ -z "$new_title" ]; then
    echo "Отменено."
    exit 0
fi

# Создаем временный файл с новым шаблоном
cd /home/acserver/server/hub
cp my_leaderboard_template.txt my_leaderboard_template.txt.backup

# Заменяем первую строку (заголовок)
sed -i "1s/.*/$new_title/" my_leaderboard_template.txt

echo ""
echo "Применяю изменения..."
python3 update_template_simple.py my_leaderboard_template.txt

echo ""
echo "✅ Готово! Проверьте Discord."
