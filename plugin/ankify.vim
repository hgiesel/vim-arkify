if exists('g:ankify_vim_loaded')
  finish
endif
let s:plugindir = expand('<sfile>:p:h:h')

let g:Pecho=[]

function! Recho()
  let g:Pecho = []
endfunction

function! Pecho(msg)
  for msgitem in a:msg
    if index(g:Pecho, msgitem) == -1 && msgitem != ''
      let g:Pecho+=a:msg
    endif
  endfor
endfunction

autocmd BufWritePost * if g:Pecho != []
      \| echohl ErrorMsg
      \| for mes in g:Pecho | echo mes | endfor
      \| echohl None
      \| let g:Pecho=[]
      \| endif

" Plugs
nmap <silent> <Plug>(AnkifyNextFile)    :call meta#page_go_rel(1)<cr>
nmap <silent> <Plug>(AnkifyPrevFile)    :call meta#page_go_rel(-1)<cr>
nmap <silent> <Plug>(AnkifyUpFile)      :call meta#page_go_up()<cr>
nmap <silent> <Plug>(AnkifyUpUpFile)    :call meta#page_go_upup()<cr>

nmap <silent> <Plug>(AnkifyAnkiAddCard) :call mappings#arkadd()<cr>
nmap <silent> <Plug>(AnkifyAnkiBrowse) :call mappings#copy('b')<cr>

nmap <silent> <Plug>(AnkifyInsertHash) :.!grand 8<cr>
nmap <silent> <Plug>(AnkifyNewPage) :.! read b; touch "$b".adoc; echo ". <<:$b,>>"<cr>
nmap <silent> <Plug>(AnkifyDisplayStats) :call mappings#get_stats()<cr>

nmap <silent> <Plug>(AnkifyLinksInsert) :call mappings#pagerefs_insert()<cr>
nmap <silent> <Plug>(AnkifyLinksClear) :%s/<<!\?\([^>,]\+\).*>>/\=substitute('<<'.submatch(1).'>>','\n','','g')<cr>
nmap <silent> <Plug>(AnkifyLinksFollow) :call meta#follow_link_with_current_line()<cr>
nmap <silent> <Plug>(AnkifyLinksSetContext) :call meta#toc_on_leave_wrapper()<cr>

nmap <silent> <Plug>(AnkifySearchArchive) :call meta#search_archive()<cr>
nmap <silent> <Plug>(AnkifySearchTocs) :call meta#search_tocs()<cr>
nmap <silent> <Plug>(AnkifySearchTocContext) :call meta#search_toc_context()<cr>
nmap <silent> <Plug>(AnkifySearchExpandedTocContext) :call meta#search_expanded_toc_context()<cr>

nmap <silent> <localleader>u <Plug>(AnkifyUpFile)
nmap <silent> <localleader>U <Plug>(AnkifyUpUpFile)
nmap <silent> <localleader>] <Plug>(AnkifyNextFile)
nmap <silent> <localleader>[ <Plug>(AnkifyPrevFile)

nmap <silent> <localleader>n <Plug>(AnkifyNewPage)
nmap <silent> <localleader>s <Plug>(AnkifyDisplayStats)
nmap <silent> <localleader>a <Plug>(AnkifyAnkiAddCard)
nmap <silent> <localleader>b <Plug>(AnkifyAnkiBrowse)

nmap <silent> <localleader>i <Plug>(AnkifyInsertHash)

nmap <silent> <localleader>= <Plug>(AnkifyLinksInsert)
nmap <silent> <localleader>+ <Plug>(AnkifyLinksClear)
nmap <silent> <localleader>f <Plug>(AnkifyLinksFollow)
nmap <silent> <localleader>F <Plug>(AnkifyLinksSetContext)

nmap <silent> <localleader>/a <Plug>(AnkifySearchArchive)
nmap <silent> <localleader>/t <Plug>(AnkifySearchTocs)
nmap <silent> <localleader>/c <Plug>(AnkifySearchTocContext)
nmap <silent> <localleader>/C <Plug>(AnkifySearchExpandedTocContext)

" TODO should be configurable on what tags should look like
" a: count up
" b: count up (n characters long)
" c: random number (n characters long)

" autocmd BufWritePre *.* call AnkifyPrintMeta()

autocmd BufWrite $ARCHIVE_ROOT/* call meta#page_on_save()
" autocmd QuitPre $ARCHIVE_ROOT/* call meta#page_on_exit()

autocmd BufWritePost $ARCHIVE_ROOT/calendar/* call meta#cal_on_save()
autocmd BufEnter $ARCHIVE_ROOT/calendar/* call meta#cal_on_save()

autocmd BufEnter $ARCHIVE_ROOT/**/README* call meta#toc_on_enter()
autocmd BufEnter $ARCHIVE_ROOT/* call meta#page_on_enter()

autocmd BufLeave $ARCHIVE_ROOT/**/README* call meta#toc_on_leave()
autocmd BufLeave $ARCHIVE_ROOT/* call meta#page_on_leave()

command! -nargs=1 Z vimgrep "<args>" $ARCHIVE_ROOT/**/*.adoc
command! -nargs=1 Ark call Ark("<args>")

function! Ark(args)
  echo a:args

  let l:path = system("ark paths '" . a:args . "'")[0:-2] " skip newline at the end

  if l:path[-1:] == ':'
    " edit if path contains lineno
    let l:cmd_pre = '+silent\\ execute\\ ''normal!\\ '
    let l:cmd_post = 'G\\ zMzv'''
    let l:path = substitute(l:path, '\(.*\):\(\d*\):', l:cmd_pre.'\2'.l:cmd_post.' \1', '')
  endif

  " echo l:path
  execute 'edit '.l:path
endfunction

let g:ankify_vim_loaded = v:true
