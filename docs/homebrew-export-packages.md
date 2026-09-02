# Homebrew: How to export packages

## Export formula
```sh
brew info --formula --json=v2 $(brew list --formula) | jq -r '.formulae[] | [{name, tap}]'
```

- Export casks
```sh
brew info --cask --json=v2 $(brew list --cask) | jq -r '.casks[] | select(.depends_on != {}) | {token, tap}'
```

Since Homebrew 6.0, any non-official binary built need to perform tap trust to be able to download, see [here](https://docs.brew.sh/Tap-Trust) for details.
