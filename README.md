# Noctalia Cursor Size

Plugin de [Noctalia](https://noctalia.dev) que aplica **apenas o tamanho** do ponteiro do mouse na inicialização e sempre que você mudar a configuração. O **tema do cursor não é alterado** e nada é baixado.

Funciona em **niri**, **Hyprland** e **Sway**, além de aplicar o tamanho via `gsettings` para aplicativos GTK.

Padrão: **48 px**.

## Por que existe

O niri não expõe o tamanho do cursor via IPC: ele só lê `cursor { xcursor-size 48 }` do `config.kdl`. Este plugin faz essa alteração de forma idempotente, com backup automático, e deixa o niri recarregar a configuração sozinho.

É a versão sem tema do [noctalia-cursor-manager](https://github.com/CarlosRgoku/noctalia-cursor-manager). Use uma ou outra, não as duas ao mesmo tempo.

## Instalação

```bash
git clone https://github.com/CarlosRgoku/noctalia-cursor-size.git
cd noctalia-cursor-size
./install.sh
```

O script copia o plugin para `~/.local/share/noctalia/plugins/cursor-size/` e habilita com:

```bash
noctalia msg plugins enable my-tools/cursor-size
```

Manual:

```bash
mkdir -p ~/.local/share/noctalia/plugins/cursor-size
cp -r plugin.toml service.luau apply-niri.sh translations ~/.local/share/noctalia/plugins/cursor-size/
noctalia msg plugins enable my-tools/cursor-size
```

## Uso

Mudar pelo painel: **Settings → Plugins → Cursor Size**.

Ou por IPC, sem reiniciar nada:

```bash
noctalia msg plugin my-tools/cursor-size:service all set 64
noctalia msg plugin my-tools/cursor-size:service all apply
```

Verificar se está ativo:

```bash
noctalia msg plugins list | grep cursor-size
```

## O que ele altera

| Ambiente | Ação |
| --- | --- |
| niri | Reescreve somente `xcursor-size` em `~/.config/niri/config.kdl` |
| Hyprland | `hyprctl setcursor <tema-atual> <tamanho>` |
| Sway | `swaymsg seat - xcursor_theme <tema-atual> <tamanho>` |
| GTK (todos) | `gsettings set org.gnome.desktop.interface cursor-size` |

O tema continua sendo o que já está configurado no sistema.

A edição do `config.kdl` é feita pelo `apply-niri.sh`, que roda `niri validate` no arquivo gerado antes de gravar. Se o resultado for inválido, nada é alterado.

Antes da primeira alteração no niri, é criado um backup em:

```
~/.config/niri/config.kdl.bak-cursor-size
```

## Trocar do cursor-manager (com tema) para este

```bash
noctalia msg plugins disable my-tools/cursor-manager
./install.sh
```

## Desinstalar

```bash
noctalia msg plugins disable my-tools/cursor-size
rm -rf ~/.local/share/noctalia/plugins/cursor-size
```

Para restaurar o tamanho original do niri:

```bash
cp ~/.config/niri/config.kdl.bak-cursor-size ~/.config/niri/config.kdl
```

## Requisitos

- Noctalia v5 ou mais recente
- `plugin_api` 24 (suportado pelo Noctalia atual)
- niri, Hyprland ou Sway (GTK funciona em qualquer ambiente)

## Licença

MIT
