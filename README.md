# Mosquera Environment

Fuente de verdad del entorno personal portable de Jalberth Mosquera.

Esta primera instantanea contiene configuracion reproducible y un instalador portable.

## Install

```bash
git clone https://github.com/jalmosquera/mosquera_environment.git
cd mosquera_environment
./install workstation
```

Perfiles: `core`, `server`, `workstation` y `full`. Sin perfil, el instalador pregunta interactivamente; sin terminal interactiva usa `core`.

Antes de modificar una maquina, revisa el plan con:

```bash
./install workstation --dry-run
```

El instalador crea backups recuperables en `~/.mosquera-soft/backups/` cuando necesita reemplazar una configuracion existente.

## Doctor

```bash
./doctor
```

`doctor` es estrictamente de solo lectura. Tras una instalacion exitosa conoce el perfil instalado; antes de que exista ese estado, ejecuta comprobaciones `core` y muestra un warning. Se puede indicar el perfil de forma explicita con `./doctor --profile workstation`.

Fish mantiene su estado mutable, incluido `fish_variables`, en `~/.config/fish`. El instalador enlaza solamente los archivos declarativos. Para migrar una instalacion anterior que enlazaba todo el directorio, ejecuta:

```bash
./install --configure-fish
```

## Update

```bash
./update
./update --dry-run
```

`update` fetches each repository and only applies a fast-forward when its working tree is clean. Local changes, missing upstreams and divergence are reported without stashing, merging, rebasing or overwriting data.

## Alcance inicial

- Fish, tmux, Neovim y Starship.
- Inventario de dependencias y perfiles propuestos.
- Referencia al repositorio independiente `jalmosquera/chatsManager`.

## Excluido deliberadamente

- Secretos, tokens, claves y credenciales.
- Historiales, caches, estado de plugins y archivos generados.
- Configuracion de aplicaciones no incluida en el objetivo de terminal.
- Rutas personales y configuracion de maquina.

## Estado

Fase 4: instalador inicial. `update`, `doctor`, sincronizacion automatica y TUI completa quedan pendientes.
