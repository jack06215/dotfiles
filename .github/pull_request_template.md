Configures Git to use Vim as the default pager and diff/merge tool.

This change:
- Sets Vim as the pager for `git log`, `git diff`, and other commands that produce paginated output
- Configures Vim in read-only mode with proper syntax highlighting for git output  
- Sets `vimdiff` as the default tool for viewing and merging diffs
- Includes a workaround for color codes in the core pager configuration

This enables a consistent, keyboard-friendly experience for viewing and resolving changes directly in Vim.
