function Edit-Profile {
    <#
        .SYNOPSIS
        Open the PowerShell profile in the editor.

        .DESCRIPTION
        Opens $PROFILE.CurrentUserCurrentHost with `vim`, which the profile
        aliases to the first of nvim, vim, code, notepad++ and notepad it
        finds.

        That file is the copy in Documents\PowerShell, which chezmoi
        overwrites on the next apply. A change meant to last belongs in the
        dotfiles repo, in dot_config/powershell/Microsoft.PowerShell_profile.ps1.

        .EXAMPLE
        Edit-Profile
    #>
    # CurrentUserCurrentHost, not CurrentUserAllHosts: the file this repo manages
    # is Microsoft.PowerShell_profile.ps1, and AllHosts would open a profile.ps1
    # that does not exist.
    vim $PROFILE.CurrentUserCurrentHost
}
