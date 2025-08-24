## Деплой Minecraft сервера через GitHub Actions

Этот репозиторий содержит пайплайн GitHub Actions для деплоя на удалённый сервер по SSH, установки (или обновления) PostgreSQL и Redis в Docker, а также синхронизации конфигураций, плагинов и серверного `.jar`.

### Структура репозитория

- `plugins/` — скомпилированные `.jar` плагинов. Копируются в `server/plugins/` на удалённой машине.
- `server/` — `.jar` файла(ы) сервера. Копируются в корень установленного сервера.
- `configs/` — директории и файлы конфигураций, которые мержатся в папку установленного сервера.
- `.github/workflows/deploy.yml` — workflow GitHub Actions.
- `scripts/remote_deploy.sh` — скрипт, запускаемый на удалённой машине.

### Секреты репозитория (Settings → Secrets and variables → Actions)

Обязательные:

- `SSH_HOST` — адрес удалённого сервера
- `SSH_USER` — пользователь SSH
- `SSH_PRIVATE_KEY` — приватный ключ SSH (PEM)
- `REMOTE_APP_DIR` — путь до директории приложения на сервере, например `/opt/minecraft/app`
- `MINECRAFT_DIR` — путь до установленного сервера, например `/opt/minecraft/server`
- `POSTGRES_PASSWORD` — пароль PostgreSQL

Опциональные (имеют значения по умолчанию):

- `SSH_PORT` — порт SSH (по умолчанию `22`)
- `POSTGRES_USER` — имя пользователя БД (по умолчанию `minecraft`)
- `POSTGRES_DB` — имя БД (по умолчанию `minecraft`)
- `REDIS_PASSWORD` — пароль Redis (если не задан, Redis запускается без пароля)

### Как работает деплой

1. Триггер: push в `main` или ручной запуск `workflow_dispatch`.
2. Экшен подключается к серверу по SSH.
3. Устанавливает `git` и `docker` при необходимости.
4. Клонирует/обновляет репозиторий на сервере в `REMOTE_APP_DIR`.
5. Запускает `scripts/remote_deploy.sh`, который:
   - поднимает `postgres:15-alpine` и `redis:7-alpine` в Docker с volume-папками
   - синхронизирует `configs/` → `MINECRAFT_DIR/`
   - синхронизирует `plugins/` → `MINECRAFT_DIR/plugins/`
   - копирует `server/*.jar` → `MINECRAFT_DIR/`

После деплоя перезапустите процесс/сервис Minecraft сервера (systemd/screen/tmux) для применения изменений.

### Ручной запуск для другой ветки

В `workflow_dispatch` можно указать `branch`. По умолчанию — текущая ветка пуша.
