# HHKB Studio keymaps (repo only)

These files are exports from HHKB Keymap Tool for the HHKB Studio keyboard.
chezmoi does not install them, because no program reads them from `$HOME`.
You import them into the keyboard by hand.

| File | Keymap for |
| --- | --- |
| [`hhkb_studio_settings_macos.hks`](hhkb_studio_settings_macos.hks) | macOS |
| [`hhkb_studio_settings_windows.hks`](hhkb_studio_settings_windows.hks) | Windows |

The files are JSON. Only the `Keymap` object is different between them. The DIP
switches, the pointing stick and the gesture pad settings are the same.

## Change a keymap

1. Open the `.hks` file for the OS in HHKB Keymap Tool.
2. Change the keymap and write it to the keyboard.
3. Export the keymap over the same file, then commit it.
