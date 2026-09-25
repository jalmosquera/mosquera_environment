# MOSQUERA SOFT
## Environment Installer

Un entorno de desarrollo reproducible y multiplataforma de Jalberth Mosquera. Mosquera Soft instala, configura, diagnostica y actualiza una experiencia de terminal consistente sin convertir el repositorio en estado mutable de una maquina.

**Soporte oficial:** macOS / Homebrew · Ubuntu y Debian / apt · Arch Linux y Omarchy / pacman

## Quick Start

Precondiciones:

- Linux: `git` y `curl`
- macOS: `git`, `curl` y [Homebrew](https://brew.sh/)

```bash
git clone https://github.com/jalmosquera/mosquera_environment.git
cd mosquera_environment
./install workstation
```

Antes de cambiar una maquina, inspecciona el plan:

```bash
./install workstation --dry-run
```

Diagnostica la instalacion sin modificarla:

```bash
./doctor
```

Actualiza los repositorios solo cuando sea seguro hacerlo:

```bash
./update
```

## Terminal Stack

| Shell and workflow | Navigation and search | Development and history |
| --- | --- | --- |
| Fish · tmux · Starship | fzf · ripgrep · fd · bat · zoxide | Neovim · Atuin · Carapace · GitHub CLI · chatsManager |

El [catalogo de dependencias](catalog/packages.toml) contiene el detalle de paquetes, mapeos por plataforma y notas de compatibilidad.

## Capturas

La UX se adapta al terminal: una TTY muestra marca, secciones y progreso; CI, SSH no interactivo, pipes y redirecciones usan lineas estables y sin ANSI.

```text
MOSQUERA SOFT | install | macOS arm64 | brew | profile: workstation
DRY RUN: no changes will be made.

[OK] Git - already installed
[PROGRESS] 2/21 (9%) - git
[SKIP] verification - skipped in dry-run
```

Las capturas reales se agregaran en `docs/assets/` cuando se generen en una terminal representativa. Este bloque corresponde a la salida real no interactiva de `./install workstation --dry-run`.

## Caracteristicas

- Instalacion reproducible para macOS, Ubuntu/Debian y Arch/Omarchy.
- Perfiles `core`, `server`, `workstation` y `full`.
- UX adaptativa para TTY y no-TTY, con `--dry-run` y `--verbose`.
- `doctor` estrictamente read-only, con resumen de salud, advertencias y fallos.
- `update` seguro mediante fast-forward unicamente.
- Logs persistentes fuera del repositorio en `${XDG_STATE_HOME:-~/.local/state}/mosquera-soft/logs/`.
- Backups antes de reemplazar configuracion existente en `~/.mosquera-soft/backups/`.
- Configuracion declarativa versionada separada del runtime mutable de Fish.
- Integracion de `chatsManager` como repositorio independiente.

## Operaciones

```bash
# Instalar un perfil; sin perfil solicita uno en TTY y usa core fuera de TTY.
./install workstation

# Mostrar cada comando y su salida para diagnostico.
./install workstation --verbose

# Validar la salud sin modificar archivos o repositorios.
./doctor --profile workstation

# Ver la actualizacion segura sin hacer cambios.
./update --dry-run

# Mostrar la salida completa de fetch y fast-forward.
./update --verbose
```

Cuando una operacion falla, Mosquera Soft conserva el exit code, identifica el comando relevante y muestra las ultimas lineas del log junto a su ubicacion.

## Update Seguro

`update` solo aplica un fast-forward cuando el repositorio tiene un working tree limpio y la rama actual sigue a un upstream valido. No ejecuta automaticamente:

- `reset`
- `rebase`
- `stash`
- `force push`
- resolucion destructiva de conflictos

Repositorios `dirty`, `ahead` o `diverged` se reportan y se protegen en lugar de sobrescribirse.

## Estructura

```text
config/    Configuracion declarativa de Fish, tmux, Starship y Neovim.
catalog/   Dependencias logicas y mapeos por plataforma.
lib/       Presentacion compartida, logs y adaptacion TTY/no-TTY.
tests/     Smoke tests Linux y pruebas de UX.
install    Motor de instalacion y configuracion de perfiles.
doctor     Diagnostico estrictamente de solo lectura.
update     Actualizacion segura de repositorios con fast-forward.
```

## Estado Local

Mosquera Soft evita guardar estado mutable en este repositorio. Usa XDG state para perfiles y logs; Fish conserva variables generadas en `~/.config/fish`. Para migrar una instalacion anterior que enlazaba todo el directorio de Fish, ejecuta:

```bash
./install --configure-fish
```

No se incluyen secretos, tokens, claves, historiales, caches ni configuracion especifica de una maquina.
