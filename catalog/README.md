# Dependency Catalog

Este catalogo es la declaracion de dependencias para el futuro instalador. Los perfiles se componen por grupos para evitar duplicar listas.

| Perfil | Incluye |
| --- | --- |
| `core` | `terminal`, `cheatsheets` |
| `server` | `terminal`, `cheatsheets` |
| `workstation` | `core`, `development` |
| `full` | `workstation`, `desktop` |

`server` y `core` tienen la misma base de paquetes. La diferencia futura es de configuracion: `server` no activara auto-tmux ni integraciones desktop, y no agregara clipboard grafico.

Docker no pertenece a ningun perfil: aparece solo en aliases y debe ser una opcion explicita futura.
