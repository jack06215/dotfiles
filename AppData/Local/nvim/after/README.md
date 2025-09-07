# `after/` Directory in Neovim

This directory is used for defining **override or extension configurations** that are loaded **after Neovim's defaults** and plugin-provided settings.

## 🔧 Purpose

Neovim automatically loads files in the `after/` directory **after all other runtime files**. This makes it useful for:

- Overriding plugin defaults
- Applying additional filetype-specific settings
- Fine-tuning behavior without modifying upstream plugin code

## 📁 Typical Structure

```
after/
├── ftplugin/
│   ├── python.lua       # Python-specific settings
│   ├── markdown.lua     # Markdown tweaks
│   └── …
├── plugin/
│   └── example.lua      # Overrides for specific plugin behavior
└── README.md
```