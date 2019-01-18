"""""""""""""""""""" Key mappings for archive """"""""""""""""""""""""

function! AdocJumpToRelativeFile(i)
  let currentFile = expand('%:t')
  " get the number of the end of file name
  let index = string(str2nr(currentFile[strlen(currentFile) - 6]) + a:i)
  let newFile = substitute(currentFile, "\\d", index, "")

  if filereadable(newFile)
    execute "edit " . newFile
  endif
endfunction

nmap <silent> <Plug>(AdocJumpToNextFile) :call AdocJumpToRelativeFile(1)<cr>
nmap <silent> <Plug>(AdocJumpToPrevFile) :call AdocJumpToRelativeFile(-1)<cr>

nmap <silent> <localleader>f <Plug>AdocJumpToNextFile
nmap <silent> <localleader>F <Plug>AdocJumpToPrevFile

function! AdocCopy(mode)
  if a:mode == 'f'
    let @+=(b:ftag)
    return
  endif

  if match(getline('.'), '^:\d\{1,4\}\a*:$') != -1

    if a:mode == 'q'
      let @+='card:1 tag:'.(b:ftag).' Quest:"*'.(getline('.')).'*"'

    elseif a:mode == 'v'
      let l:qq='card:1 tag:'.(b:ftag).' Quest:\"*'.(getline('.')).'*\"'
      call system('curl localhost:8765 -X POST -d ''{"action":"guiBrowse","version":6,"params":{"query": "'.l:qq.'"}}''')

    elseif a:mode == 't'
      let @+=(b:ftag).(getline('.'))
    endif

  else
    echomsg "Can only be executed on qtag lines!"
  endif
endfunction

nmap <silent> <Plug>(AdocCopyFullyQualifiedTag) :call AdocCopy('t')<cr>
nmap <silent> <Plug>(AdocCopyFtag) :call AdocCopy('f')<cr>
nmap <silent> <Plug>(AdocCopyBlock) vip:s/\[\[oc\d::\(\_.\{-}\)\(::[^:]*\)\?\]\]/\1/ge<cr>"+yip
nmap <silent> <Plug>(AdocCopyAnkiQuery) :call AdocCopy('q')<cr>
nmap <silent> <Plug>(AdocAnkiQuery) :call AdocCopy('v')<cr>
nmap <silent> <Plug>(AdocAnkiAddCard) :call AdocCopy('v')<cr>

nmap <silent> <localleader>t <Plug>(AdocCopyFullyQualifiedTag)
nmap <silent> <localleader>T <Plug>(AdocCopyFtag)
nmap <silent> <localleader>q <Plug>(AdocCopyAnkiQuery)
nmap <silent> <localleader>v <Plug>(AdocAnkiQuery)
nmap <silent> <localleader>Q <Plug>(AdocCopyBlock)

function! AdocInsert(mode)
  if !empty(b:qtags_unique)
    execute 'normal! 0Di:'.(b:qtags_unique[-1] + 1).':'
  else
    execute 'normal! 0Di:1:'
  endif

  silent write
  call AdocPrintMeta()
endfunction

nmap <silent> <Plug>(AdocInsertTag) :call AdocInsert('t')<cr>
nmap <silent> <localleader>i <Plug>AdocInsertTag
