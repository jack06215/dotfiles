# PowerShell Profile

This repository contains my PowerShell profile to enhance command-line experience on Windows. The profile script (`Microsoft.PowerShell_profile.ps1`) provides a set of utility functions for productivity.

## Features

- **Help System**:  
  Use `Show-Help` to display a summary of all available commands and their descriptions.

- **Profile and PowerShell Management**:  
  - `Edit-Profile`: Quickly open your profile for editing in your preferred editor.  
  - `Update-Profile`: (If implemented) Update your profile from a remote repository.  
  - `Update-PowerShell`: Check for and install the latest PowerShell release.

- **File and System Utilities**:  
  - `touch <file>`: Create a new empty file.  
  - `ff <name>`: Recursively find files by name.  
  - `unzip <file>`: Extract a zip file to the current directory.  
  - `df`: Display information about system volumes.  
  - `sed <file> <find> <replace>`: Replace text in a file.  
  - `which <name>`: Show the path of a command.  
  - `export <name> <value>`: Set an environment variable.

- **Process Management**:  
  - `pkill <name>`: Kill processes by name.  
  - `pgrep <name>`: List processes by name.

- **Text Search and Manipulation**:  
  - `grep <regex> [dir]`: Search for a regex pattern in files or from pipeline input.  
  - `grep-table`: Format matching objects as a table.  
  - `head <path> [n]`: Show the first n lines of a file.  
  - `tail <path> [n]`: Show the last n lines of a file.

- **System Information**:  
  - `uptime`: Display system uptime and last boot time.  
  - `Get-PubIP`: Show your public IP address.

- **Admin and Reload**:  
  - `admin [args]`: Open a new elevated Windows Terminal session, optionally running a command.  
  - `Reload-Profile`: Reload the current profile.

- **Package Management**:  
  - `Install-Packages`: Installs essential packages, including Chocolatey, Terminal-Icons, and Nerd Fonts.
  - `Install-ChocolateyAppsMenu`: Interactive menu to install or upgrade apps from `defaultapps.config` and `devapps.config`.

## Startup Enhancements

- Sets up command prediction and increases command history size.
- Automatically installs essential tools and fonts on startup.
- Sets up your preferred editor as the `vim` alias.

## Configuration Files

- `defaultapps.config` and `devapps.config`: Lists of applications to install via Chocolatey.
- `profile.ps1`: Additional user profile customizations and aliases.

## Usage

1. Place `Microsoft.PowerShell_profile.ps1` in your PowerShell profile directory (e.g., `$HOME\Documents\PowerShell\`).
2. Restart PowerShell to load the profile.
3. Use `Show-Help` to see available commands.

## Requirements

- Windows PowerShell 5+ or PowerShell Core.
- [Chocolatey](https://chocolatey.org/) for package management.
- Internet access for downloading fonts and updates.
- ` Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`
