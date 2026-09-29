function export($name, $value) {
    <#
        .SYNOPSIS
        Set an environment variable for this session.

        .DESCRIPTION
        Like `export NAME=value` in a POSIX shell, except that the name and
        value are separate arguments. Only this process and the ones it
        starts see the variable; it is not saved.

        .PARAMETER name
        The variable name.

        .PARAMETER value
        The value to give it.

        .EXAMPLE
        export EDITOR nvim
    #>
    set-item -force -path "env:$name" -value $value;
}
