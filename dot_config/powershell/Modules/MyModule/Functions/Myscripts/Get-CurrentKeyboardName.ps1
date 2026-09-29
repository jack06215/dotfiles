function Get-CurrentKeyboardName {
    <#
        .SYNOPSIS
        Print the current keyboard language, as get_keyboard_language.py reports it.

        .DESCRIPTION
        Runs $HOME\myscripts\get_keyboard_language.py with whichever `python`
        is first on PATH. That script is not in this repo, so it has to be put
        in place separately.

        .EXAMPLE
        Get-CurrentKeyboardName
    #>
    python "$HOME/myscripts/get_keyboard_language.py"
}
