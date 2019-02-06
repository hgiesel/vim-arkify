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

" Global variables
let g:ankify_deckName   = 'misc::head'
let g:ankify_modelName  = 'Cloze (overlapping)'
let g:ankify_mainField  = 'Quest'
" unimplemented
let g:ankify_questField = 'Cloze (overlapping)'


function! s:follow_link()
  let l:view = winsaveview()

  let l:link_word = getline('.')

  let l:arkId     = substitute(l:link_word, '.*<<!\?\([^<,>]*\).*', '\1', '')
  let l:fileName  = system('ark paths '.l:arkId)

  if v:shell_error == 0
    execute 'edit '.l:fileName
  else
    echom 'No such file: '.l:fileName
  endif

  normal! 

  call winrestview(l:view)
endfunction

" Plugs

nmap <silent> <Plug>(AnkifyLinksFollow) :call <sid>follow_link()<cr>

nmap <silent> <Plug>(AnkifyNextFile)    :call meta#page_go_rel(1)<cr>
nmap <silent> <Plug>(AnkifyPrevFile)    :call meta#page_go_rel(-1)<cr>
nmap <silent> <Plug>(AnkifyUpFile)      :call meta#page_go_up()<cr>

nmap <silent> <Plug>(AnkifyCopyFullyQualifiedTag) :call mappings#copy('t')<cr>
nmap <silent> <Plug>(AnkifyCopyFtag) :call mappings#copy('f')<cr>
nmap <silent> <Plug>(AnkifyCopyBlock) vip:s/\[\[oc\d::\(\_.\{-}\)\(::[^:]*\)\?\]\]/\1/ge<cr>"+yip

nmap <silent> <Plug>(AnkifyLinksInsert) :%s/\%(<<.*\)\@<=\([^>,]\+\).*\%(>>\)\@=/\=substitute(submatch(1).','.system('ark headings -p=none '.submatch(1).'<bar>head -1<bar>cut -f1'), '\n','','g')<cr>
nmap <silent> <Plug>(AnkifyLinksClear) :%s/<<!\?\([^>,]\+\).*>>/\=substitute('<<'.submatch(1).'>>','\n','','g')<cr>


nmap <silent> <Plug>(AnkifyCopyAnkiQuery) :call mappings#copy('q')<cr>
nmap <silent> <Plug>(AnkifyAnkiQuery) :call mappings#copy('v')<cr>

nmap <silent> <Plug>(AnkifyAnkiAddCard) :call mappings#copy('a')<cr>
nmap <silent> <Plug>(AnkifyAnkiBrowse) :call mappings#copy('b')<cr>

nmap <silent> <Plug>(AnkifyInsertTag) :call mappings#insertTag('c',2)<cr>
nmap <silent> <Plug>(AnkifyInsertHash) :.!grand 8<cr>

nmap <silent> <localleader>u <Plug>(AnkifyUpFile)
nmap <silent> <localleader>] <Plug>(AnkifyNextFile)
nmap <silent> <localleader>[ <Plug>(AnkifyPrevFile)

nmap <silent> <localleader>t <Plug>(AnkifyCopyFullyQualifiedTag)
nmap <silent> <localleader>T <Plug>(AnkifyCopyFtag)
nmap <silent> <localleader>q <Plug>(AnkifyCopyAnkiQuery)

nmap <silent> <localleader>v <Plug>(AnkifyAnkiQuery)
nmap <silent> <localleader>a <Plug>(AnkifyAnkiAddCard)
nmap <silent> <localleader>b <Plug>(AnkifyAnkiBrowse)

nmap <silent> <localleader>i <Plug>(AnkifyInsertTag)
nmap <silent> <localleader>I <Plug>(AnkifyInsertHash)

nmap <silent> <localleader>= <Plug>(AnkifyLinksInsert)
nmap <silent> <localleader>+ <Plug>(AnkifyLinksClear)
nmap <silent> <localleader>f <Plug>(AnkifyLinksFollow)

" TODO should be configurable on what tags should look like
" a: count up
" b: count up (n characters long)
" c: random number (n characters long)

" autocmd BufWritePre *.* call AnkifyPrintMeta()

autocmd BufWrite $ARCHIVE_ROOT/* call meta#page_on_save()
" autocmd QuitPre $ARCHIVE_ROOT/* call meta#page_on_exit()

autocmd BufEnter $ARCHIVE_ROOT/**/README* call meta#toc_on_enter()
autocmd BufEnter $ARCHIVE_ROOT/* call meta#page_on_enter()

autocmd BufLeave $ARCHIVE_ROOT/**/README* call meta#toc_on_leave()
autocmd BufLeave $ARCHIVE_ROOT/* call meta#page_on_leave()

command! -nargs=1 Z vimgrep "<args>" $ARCHIVE_ROOT/**/*.adoc

let g:ankify_vim_loaded = v:true
