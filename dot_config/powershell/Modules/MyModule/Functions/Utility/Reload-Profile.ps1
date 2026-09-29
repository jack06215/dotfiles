function Reload-Profile {
    <#
        .SYNOPSIS
        Run the PowerShell profile again.

        .DESCRIPTION
        The profile runs in a child scope, so what it changes session-wide -
        environment variables, PSReadLine options - takes effect, but the
        aliases it sets are gone again when it returns, and MyModule is not
        re-imported, since it is already loaded.

        For a full reload, dot-source the profile at the prompt instead:
        . $PROFILE
        To pick up changes to MyModule: Import-Module MyModule -Force

        .EXAMPLE
        Reload-Profile
    #>
    & $profile
}
