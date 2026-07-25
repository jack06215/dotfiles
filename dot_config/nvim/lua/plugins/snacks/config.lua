return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    image = {
      -- Drop "pdf" from the default image formats so snacks doesn't register a
      -- `BufReadCmd *.pdf` that shells out to ImageMagick/ghostscript (`gs`).
      -- `gs` isn't installed here, so that conversion fails; instead we let
      -- PDFs open as a normal buffer (see the `pdf = "text"` filetype rule in
      -- lua/config/general.lua). This mirrors the snacks defaults minus "pdf".
      formats = {
        "png",
        "jpg",
        "jpeg",
        "gif",
        "bmp",
        "webp",
        "tiff",
        "heic",
        "avif",
        "mp4",
        "mov",
        "avi",
        "mkv",
        "webm",
        "icns",
      },
    },
  },
}
