" vim: set ft=vim :
" Additions on top of vim's bundled gitcommit ftplugin, which already covers
" textwidth=72, formatoptions+=tl and nomodeline.
"
" The buffer this mostly sees is the one `gcm` builds in git.zsh: line 1
" pre-filled as `type(scope): `, then a `# :wq! to commit` / `# :cq! to
" discard commit` banner and the staged diff, every line comment-prefixed.

" 51 marks the 50-char subject limit, 73 the 72-char body wrap.
setlocal colorcolumn=51,73
setlocal spell spelllang=en_us
" The diff block below the banner is dense enough without listchars on it.
setlocal nolist
" Throwaway buffers in a mktemp dir - no reason to accrue undo history.
setlocal noundofile
" No completion popup while writing prose. This is the buffer variable that
" asyncomplete#disable_for_buffer() sets; assigning it directly avoids an
" exists('*...') guard on an autoload function, which can never be true until
" something has already called into that autoload file.
let b:asyncomplete_enable = 0

" Land at the end of gcm's prefix and start typing. Guarded on the trailing
" colon so a plain `git commit` (empty line 1) still opens in normal mode at
" the top, and on argc() so opening a commit message inside an existing
" session doesn't yank you into insert.
if getline(1) =~# ':\s*$'
  call cursor(1, col([1, '$']))
  if argc() <= 1
    autocmd VimEnter <buffer> ++once startinsert!
  endif
endif
