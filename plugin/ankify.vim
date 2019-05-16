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

function! s:follow_link()
  let l:view = winsaveview()

  let l:ark_uri = substitute(getline('.'), '.*<<!\?\([^<,>]*\).*', '\1', '')

  " I can guess the link if it starts with colon
  if l:ark_uri[0] == ':'
    execute 'edit '.l:ark_uri[1:-1].'.*'

  " Or when I'm in a toc context
  elseif exists('w:toc_current') && exists('w:toc_linenos') && index(w:toc_linenos, line('.')) != -1
    execute 'edit '.w:toc_files[index(w:toc_linenos, line('.'))]

  " Otherwise I have to process it
  else
    let l:file_name  = system('ark paths '.l:ark_uri.' | head -c -1')

    if v:shell_error == 0 && filereadable(l:file_name)
      execute 'edit '.l:file_name
    else
      echom 'No such file: '.l:file_name
    endif
  end

  normal! 
  call winrestview(l:view)
endfunction

" Plugs
nmap <silent> <Plug>(AnkifyLinksFollow) :call <sid>follow_link()<cr>

nmap <silent> <Plug>(AnkifyNextFile)    :call meta#page_go_rel(1)<cr>
nmap <silent> <Plug>(AnkifyPrevFile)    :call meta#page_go_rel(-1)<cr>
nmap <silent> <Plug>(AnkifyUpFile)      :call meta#page_go_up()<cr>
nmap <silent> <Plug>(AnkifyUpUpFile)    :call meta#page_go_upup()<cr>

nmap <silent> <Plug>(AnkifyCopyFullyQualifiedTag) :call mappings#copy('t')<cr>
nmap <silent> <Plug>(AnkifyCopyFtag) :call mappings#copy('f')<cr>
nmap <silent> <Plug>(AnkifyCopyBlock) vip:s/\[\[oc\d::\(\_.\{-}\)\(::[^:]*\)\?\]\]/\1/ge<cr>"+yip

nmap <silent> <Plug>(AnkifyLinksInsert) :call mappings#pagerefs_insert()<cr>
nmap <silent> <Plug>(AnkifyLinksClear) :%s/<<!\?\([^>,]\+\).*>>/\=substitute('<<'.submatch(1).'>>','\n','','g')<cr>

nmap <silent> <Plug>(AnkifyCopyAnkiQuery) :call mappings#copy('q')<cr>
nmap <silent> <Plug>(AnkifyAnkiQuery) :call mappings#copy('v')<cr>

nmap <silent> <Plug>(AnkifyAnkiAddCard) :call mappings#arkadd()<cr>
nmap <silent> <Plug>(AnkifyAnkiBrowse) :call mappings#copy('b')<cr>

nmap <silent> <Plug>(AnkifyInsertTag) :call mappings#insertTag('c', 3)<cr>
nmap <silent> <Plug>(AnkifyInsertHash) :.!grand 8<cr>
nmap <silent> <Plug>(AnkifyNewPage) :.! read b; touch "$b".adoc; echo ". <<:$b,>>"<cr>
nmap <silent> <Plug>(AnkifyDisplayStats) :call mappings#get_stats()<cr>

nmap <silent> <Plug>(AnkifySearchArchive) :call meta#search_archive()<cr>
nmap <silent> <Plug>(AnkifySearchTocs) :call meta#search_tocs()<cr>
nmap <silent> <Plug>(AnkifySearchTocContext) :call meta#search_toc_context()<cr>

nmap <silent> <localleader>u <Plug>(AnkifyUpFile)
nmap <silent> <localleader>U <Plug>(AnkifyUpUpFile)
nmap <silent> <localleader>] <Plug>(AnkifyNextFile)
nmap <silent> <localleader>[ <Plug>(AnkifyPrevFile)

nmap <silent> <localleader>t <Plug>(AnkifyCopyFullyQualifiedTag)
nmap <silent> <localleader>T <Plug>(AnkifyCopyFtag)
nmap <silent> <localleader>q <Plug>(AnkifyCopyAnkiQuery)

nmap <silent> <localleader>n <Plug>(AnkifyNewPage)

nmap <silent> <localleader>v <Plug>(AnkifyAnkiQuery)
nmap <silent> <localleader>a <Plug>(AnkifyAnkiAddCard)
nmap <silent> <localleader>b <Plug>(AnkifyAnkiBrowse)
nmap <silent> <localleader>s <Plug>(AnkifyDisplayStats)

nmap <silent> <localleader>i <Plug>(AnkifyInsertTag)
nmap <silent> <localleader>I <Plug>(AnkifyInsertHash)

nmap <silent> <localleader>= <Plug>(AnkifyLinksInsert)
nmap <silent> <localleader>+ <Plug>(AnkifyLinksClear)
nmap <silent> <localleader>f <Plug>(AnkifyLinksFollow)

nmap <silent> <localleader>/a <Plug>(AnkifySearchArchive)
nmap <silent> <localleader>/t <Plug>(AnkifySearchTocs)
nmap <silent> <localleader>/c <Plug>(AnkifySearchTocContext)

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
