# LazyVim starter

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Installation

Make a backup.

- Windows

```ps1
# required
Move-Item $env:LOCALAPPDATA\nvim $env:LOCALAPPDATA\nvim.bak

# optional but recommended
Move-Item $env:LOCALAPPDATA\nvim-data $env:LOCALAPPDATA\nvim-data.bak
```

- MacOS

```sh
# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
```

Clone the starter.

- Windows

```ps1
git clone git@github.com:jack06215/lazyvim-starter.git $env:LOCALAPPDATA\nvim
```

- MacOS

```sh
git clone git@github.com:jack06215/lazyvim-starter.git ~/.config/nvim
```

Start Neovim

```sh
nvim
```

## Useful link
- [Ascii art generator](https://patorjk.com/software/taag/#p=display&f=BlurVision%20ASCII&t=)