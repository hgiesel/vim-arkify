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

function! s:ankify_install_utils()
  let s:plugindir = expand('<sfile>:p:h:h')
  call system('cp '.s:plugindir.'/../tools/arkutil.sh /usr/local/bin/arkutil')
endfunction

command AnkifyInstallUtils call <sid>ankify_install_utils()

let g:ankify_vim_loaded = v:true
