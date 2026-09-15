" Syntax highlighting for navi cheatsheets (https://github.com/denisidoro/navi).
"
" navi has no tree-sitter grammar - upstream ships a TextMate grammar for
" VS Code only - so this is a classic syntax script. Filetype detection lives
" in lua/config/general.lua, editor settings in after/ftplugin/cheat.lua.
"
" The structure navi's parser recognises, all of it anchored at column 0:
"
"   %     tags; also starts a new cheat block, which is the scope that `$`
"         lines and `@` extensions are keyed by
"   #     the cheat's description (its searchable title, NOT a comment)
"   ;     a real comment - navi ignores the line
"   $     pre-defined variable: `$ name: command --- opts`
"   @     extended cheat: pulls in another block's variables by tag
"   ```   fences a multi-line snippet
"
" Every other non-empty line is an executable command.

if exists('b:current_syntax')
  finish
endif

" Shell syntax is embedded so command lines look like the shell they are.
" `syn include` marks everything it pulls in as `contained`, so those rules
" only fire inside the regions below. b:is_bash has to be set first, or vim's
" sh.vim runs in POSIX mode and flags `$(...)` - which most of these snippets
" use - as an error. sh.vim sets b:current_syntax on the way out, which must be
" cleared again so the guard above does not fire for the rest of this file.
let b:is_bash = 1
syntax include @cheatShell syntax/sh.vim
unlet! b:current_syntax

" Command lines, shell-highlighted. Deliberately defined before the sigil rules
" below: those start at column 0 too, and when two items match at the same
" position vim gives precedence to whichever was defined last.
syntax region cheatCommand start='^\s*\S' end='$' keepend
      \ contains=@cheatShell,cheatVar

" A fenced snippet is one region spanning the whole fence rather than a region
" per line, so shell quoting that runs across lines - the python heredoc in
" k8s.cheat - stays highlighted as the single string it is.
syntax region cheatFence matchgroup=cheatFenceDelim start='^```\w*$' end='^```$'
      \ keepend contains=@cheatShell,cheatVar

syntax match cheatComment '^;.*$'

syntax match cheatDesc '^#.*$' contains=cheatDescSigil
syntax match cheatDescSigil '^#' contained

syntax match cheatTags '^%.*$' contains=cheatTagsSigil
syntax match cheatTagsSigil '^%' contained

syntax match cheatExtend '^@.*$' contains=cheatExtendSigil
syntax match cheatExtendSigil '^@' contained

" `$ name: command --- opts`.
"
" The suggestion command is deliberately NOT shell-highlighted. These are one
" short command each (almost always `echo`), and leaving sh.vim out of the line
" is what lets the ` --- ` tail - navi's own flags, not shell - be picked out:
" embedded sh would wrap the whole thing in an shEcho region that a plain
" `contained` item could never be reached inside.
syntax region cheatVarLine matchgroup=cheatVarSigil start='^\$' end='$' keepend
      \ contains=cheatVarName,cheatVarOpts,cheatVarString,cheatVar
syntax match cheatVarName '\%(^\$\s*\)\@<=[A-Za-z0-9_]\+\ze\s*:' contained
syntax match cheatVarOpts '\s---\s.*$' contained
syntax region cheatVarString start=+'+ end=+'+ contained contains=cheatVar
syntax region cheatVarString start=+"+ end=+"+ contained contains=cheatVar

" The placeholders navi interpolates, which is the one thing that has to stay
" visible everywhere - most of them sit inside quoted jq or python arguments.
syntax match cheatVar '<[A-Za-z0-9_]\+>'
      \ containedin=ALLBUT,cheatComment,cheatDesc,cheatTags,cheatExtend,cheatVarOpts

" containedin=ALL does not reach inside sh.vim's own regions - they carry
" explicit contains lists - so cheatVar is added to the clusters that hold
" command content: double-quoted strings, `$(...)`, `(...)`, subshells and
" echo arguments. Single quotes take only @Spell, so shSingleQuote is
" redeclared instead (vim keeps both definitions and prefers the later one).
"
" This leans on sh.vim internals, hence `silent!`: if the cluster names change
" upstream the worst case is a placeholder losing its colour inside a quote,
" not a broken syntax file. To re-check the whole set after a neovim upgrade,
" open a cheatsheet and put the cursor on each `<...>`:
"   :echo synIDattr(synID(line('.'), col('.'), 1), 'name')
" should answer cheatVar every time.
for s:cluster in ['shDblQuoteList', 'shArithParenList', 'shCommandSubList',
      \           'shSubShList', 'shEchoList', 'shTestList', 'shIdList']
  silent! execute 'syntax cluster' s:cluster 'add=cheatVar'
endfor
unlet! s:cluster

silent! syntax region shSingleQuote matchgroup=shQuote start=+'+ end=+'+
      \ contained contains=@Spell,cheatVar
      \ nextgroup=shSpecialStart,shSpecialSQ

highlight default link cheatComment      Comment
highlight default link cheatDesc         Title
highlight default link cheatDescSigil    Delimiter
highlight default link cheatTags         Type
highlight default link cheatTagsSigil    Delimiter
highlight default link cheatExtend       Include
highlight default link cheatExtendSigil  Delimiter
highlight default link cheatVarSigil     Delimiter
highlight default link cheatVarName      Identifier
highlight default link cheatVarString    String
highlight default link cheatVarOpts      PreProc
highlight default link cheatVar          Identifier
highlight default link cheatFenceDelim   Delimiter

let b:current_syntax = 'cheat'
