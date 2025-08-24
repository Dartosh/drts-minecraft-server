## Скрипт установки сервера Minecraft

### Структура репозитория

- `plugins/` — `.jar` плагинов
- `server/` — директория установленного сервера и jar-файл `server.jar`
- `configs/` — конфигурации
- `scripts/backup_worlds.sh` — сохраняет текущие миры из `server/` в `maps/<timestamp>/`
- `scripts/reinstall_server.sh` — скачивает и устанавливает `server.jar`, проставляет `eula=true`
- `scripts/restore_latest_worlds.sh` — копирует последний снапшот из `maps/<timestamp>/` в `server/`
- `scripts/start_server.sh` — запуск сервера
- `scripts/install_systemd_service.sh` — установка/пересоздание systemd-сервиса для автозапуска
- `scripts/backup_and_prune.sh` — бэкап миров и удаление старых снапшотов (по умолчанию хранит 4)
- `scripts/install_cron_backup.sh` — установка/пересоздание cron-задачи (каждые 12 часов)
- `scripts/sync_configs.sh` — копирует конфиги из `configs/` в `server/` с заменой
- `scripts/sync_plugins.sh` — копирует плагины из `plugins/` в `server/plugins/` с заменой
- `maps/` — хранилище миров. На каждый запуск создаётся снапшот `maps/<timestamp>/...` из текущих миров сервера. При установке копируются миры из последнего `maps/<timestamp>/` в `server/`.

### Использование

Примеры:

1. Снять бэкап миров:

```bash
bash scripts/backup_worlds.sh
```

2. Переустановить сервер:

```bash
bash scripts/reinstall_server.sh --new_fork Paper --url "https://example.com/paper-X.Y.Z.jar"
```

3. Восстановить последний бэкап миров на сервер:

```bash
bash scripts/restore_latest_worlds.sh
```

4. Установить сервис (Ubuntu 24.04, требует sudo):

```bash
sudo bash scripts/install_systemd_service.sh
```

5. Установить cron-задачу (каждые 12 часов бэкап + чистка до 4 снапшотов):

```bash
bash scripts/install_cron_backup.sh
```

6. Синхронизировать конфиги в сервер:

```bash
bash scripts/sync_configs.sh
```

7. Синхронизировать плагины в сервер:

```bash
bash scripts/sync_plugins.sh
```

Опции:

- `--service-name` — имя сервиса (по умолчанию `minecraft-server-service`)
- `--user` — под каким пользователем запускать
- `--workdir` — путь к корню репозитория (где `scripts/`)

Параметры:

- `--new_fork` — один из: `Bukkit`, `Spigot`, `Paper`, `Tuinity`, `Purpur`
- `--url` — ссылка на скачивание нового server jar
- `--old_fork` — (опционально) один из тех же значений; влияет на стратегию поиска миров (скрипт авто-детектит по `level.dat` и `server.properties`, параметр служит подсказкой)

Что делает:

- backup_worlds.sh — создаёт снапшот текущих миров сервера в `maps/<timestamp>/...`
- reinstall_server.sh — скачивает `server.jar` и создаёт `eula.txt` (если отсутствует)
- restore_latest_worlds.sh — переносит последний бэкап миров из `maps/<timestamp>/` в `server/`

Цепочка обновления версий:

1. Снять бэкап текущих миров (`backup_worlds.sh`).
2. Переустановить сервер (`reinstall_server.sh`).
3. Перенести последний бэкап миров на сервер (`restore_latest_worlds.sh`).

### Запуск

После установки:

```bash
bash scripts/start_server.sh
```
