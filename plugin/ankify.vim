if exists('g:ankify_vim_loaded')
  finish
endif

let s:Pecho=''
function! s:Pecho(msg)
  let s:hold_ut=&ut | if &ut>1|let &ut=1|en
  let s:Pecho=a:msg
  aug Pecho
    au CursorHold * if s:Pecho!=''| echohl ErrorMsg | echo s:Pecho | echohl None
          \|let s:Pecho=''|if s:hold_ut > &ut |let &ut=s:hold_ut|en|en
        \|aug Pecho|exe 'au!'|aug END|aug! Pecho
  aug END
endfunction

let s:plugindir = expand('<sfile>:p:h:h')

function! s:ankify_install_utils()
  let x =  writefile(readfile(s:plugindir.'/tools/arkutil.sh', 'b'), '/usr/local/bin/arkutil', 'b')

  if x == -1
    echo 'Error writing to /usr/local/bin/arkutil'
  else
    echo 'Successfully written to /usr/local/bin/arkutil'
  endif
endfunction

command AnkifyInstallUtils call <sid>ankify_install_utils()

" Global variables
let g:ankify_deckName   = 'head'
let g:ankify_modelName  = 'Cloze (overlapping)'
let g:ankify_mainField  = 'Quest'
" unimplemented
let g:ankify_questField = 'Cloze (overlapping)'

" Plugs
nmap <silent> <Plug>(AnkifyNextFile) :call AnkifyJumpToFile(1)<cr>
nmap <silent> <Plug>(AnkifyPrevFile) :call AnkifyJumpToFile(-1)<cr>

nmap <silent> <Plug>(AnkifyCopyFullyQualifiedTag) :call AnkifyCopy('t')<cr>
nmap <silent> <Plug>(AnkifyCopyFtag) :call AnkifyCopy('f')<cr>
nmap <silent> <Plug>(AnkifyCopyBlock) vip:s/\[\[oc\d::\(\_.\{-}\)\(::[^:]*\)\?\]\]/\1/ge<cr>"+yip
nmap <silent> <Plug>(AnkifyCopyAnkiQuery) :call AnkifyCopy('q')<cr>
nmap <silent> <Plug>(AnkifyAnkiQuery) :call AnkifyCopy('v')<cr>
nmap <silent> <Plug>(AnkifyAnkiAddCard) :call AnkifyCopy('a')<cr>

nmap <silent> <Plug>(AnkifyInsertTag) :call AnkifyInsert('t')<cr>

nmap <silent> <localleader>f <Plug>(AnkifyNextFile)
nmap <silent> <localleader>F <Plug>(AnkifyPrevFile)

nmap <silent> <localleader>t <Plug>(AnkifyCopyFullyQualifiedTag)
nmap <silent> <localleader>T <Plug>(AnkifyCopyFtag)
nmap <silent> <localleader>q <Plug>(AnkifyCopyAnkiQuery)
nmap <silent> <localleader>v <Plug>(AnkifyAnkiQuery)
nmap <silent> <localleader>a <Plug>(AnkifyCopyBlock)

nmap <silent> <localleader>i <Plug>AnkifyInsertTag
" TODO should be configurable on what tags should look like
" a: count up
" b: count up (n characters long)
" c: random number (n characters long)

" autocmd BufWritePre *.* call AnkifyPrintMeta()
autocmd BufEnter,BufWrite $ARCHIVE_PATH/*.* call AnkifyPrintMeta()
autocmd QuitPre $ARCHIVE_PATH/*/README.* call AnkifyPrintMetaReadme()

let g:ankify_vim_loaded = v:true
