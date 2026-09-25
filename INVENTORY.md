# Inventory

## Capturado

- Fish: inicio, aliases, funciones propias, plugins declarados y bindings.
- Tmux: configuracion activa y plugins declarados.
- Neovim: configuracion, plugins, extras y lockfile.
- Starship: tema e identidad Mosquera Soft.

## Perfiles propuestos

| Perfil | Componentes |
| --- | --- |
| core | git, curl, Fish, tmux, Neovim, fzf, ripgrep, fd, bat, less, Starship, zoxide, atuin, carapace, Python 3 y GitHub CLI |
| workstation | chatsManager, lsd, tree, Node.js, Docker CLI/Compose, herramientas de desarrollo y configuracion desktop opcional |
| server | core sin autoarranque de tmux ni integraciones graficas; Docker queda opcional |
| notes | Obsidian.nvim y una ruta de vault definida localmente |

Los aliases no fuerzan la instalacion de su herramienta. Se mantendran disponibles, pero los perfiles decidiran que binarios se instalan.

## Configuracion local futura

`PROJECT_PATHS`, el vault de Obsidian, hosts SSH y preferencias de maquina no se versionaran. El instalador generara archivos locales ignorados a partir de ejemplos.

## Hallazgos pendientes para normalizacion posterior

- Fish, tmux y Neovim contienen rutas macOS/Homebrew que deben pasar a deteccion de runtime.
- El alias `commit` apunta a un script ausente: `/Users/jalberth/Documents/customUtils/customsGIT.bash`.
- `PROJECT_PATHS` contiene el valor heredado `/home/alanbuscaglia/work`, inexistente en este Mac; `pj` por tanto no es funcional hoy.
- chatsManager ya tiene un instalador portable propio y permanece como repositorio independiente.
