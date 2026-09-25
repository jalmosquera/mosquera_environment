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

- `commit` se excluye: apuntaba a un script ausente y no existe una alternativa verificable.
- `PROJECT_PATHS` no se versiona: su valor heredado `/home/alanbuscaglia/work` es invalido. `pj` permanece disponible y requiere configuracion local por maquina.
- Los hosts SSH `jserver` e `imac` y las acciones GUI no se instalan como configuracion comun.
- chatsManager ya tiene un instalador portable propio y permanece como repositorio independiente.
