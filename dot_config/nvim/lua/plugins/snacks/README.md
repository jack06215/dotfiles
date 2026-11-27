# snacks

[folke/snacks.nvim](https://github.com/folke/snacks.nvim) is a set of small
plugins that LazyVim uses (pickers, dashboard, notifications and more). This
folder changes only the `image` part.

- **Images are off on WSL2.** WezTerm on Windows has kitty graphics off by
  default, and they are not reliable when on. ImageMagick is not installed in
  WSL2.
- **PDF is not an image format here.** snacks would convert a PDF with
  ImageMagick and `gs`, and `gs` is not installed. A PDF opens as a normal
  buffer instead, through the `pdf` filetype rule in
  [`lua/config/general.lua`](../../config/general.lua). The `formats` list is
  the snacks default list without `pdf`.

The config is in [`config.lua`](config.lua).
