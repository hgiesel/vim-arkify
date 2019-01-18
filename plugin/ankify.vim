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

function! s:ankify_get_dir()
  return s:plugindir
endfunction

execute 'command AnkifyInstallUtils call system("cp '.<sid>ankify_get_dir().'/../tools/arkutil.sh /usr/local/bin/arkutil")'

let g:ankify_vim_loaded = v:true
