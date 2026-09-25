# Doctor Contract

El futuro `doctor` debe informar estado por componente: `installed`, `already installed`, `updated` o `failed`. Nunca debe instalar ni modificar por defecto.

## Comprobaciones

| Componente | Verificacion funcional |
| --- | --- |
| Git | `git --version` |
| Fish | validar sintaxis con `fish --no-execute` sobre la configuracion instalada |
| Tmux | cargar el archivo con `tmux -f ... start-server` y comprobar `default-terminal` |
| Fzf, rg, fd, bat, less, Starship, zoxide, atuin, carapace | ejecutar `--version` |
| Python | `python3 --version` y `python3 -m venv --help` |
| chatsManager | comprobar repositorio Git, venv ejecutable y, dentro de Fish, que existan `cs` y `csfind` |
| Neovim | `nvim --headless "+quitall"` con la configuracion instalada |
| Node | `node --version`; fallar si es menor que 18 |
| Build tools | macOS: `xcode-select -p`; Linux: `make --version` |
| GitHub CLI | `gh --version`; mostrar autenticacion como pendiente, sin ejecutar login |
| Clipboard Linux | solo si hay `WAYLAND_DISPLAY` o `DISPLAY`; comprobar `wl-copy` o `xclip` segun corresponda |

## Limites

- No verificar credenciales, tokens ni claves privadas.
- No iniciar autenticacion de `gh` ni sincronizacion de Atuin.
- No iniciar Docker ni exigirlo: no pertenece a ningun perfil actual.
