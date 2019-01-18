"""""""""""""""""""" Key mappings for archive """"""""""""""""""""""""
function! ankify#mappings#jumpRelative(i)
  let currentFile = expand('%:t')
  " get the number of the end of file name
  let index = string(str2nr(currentFile[strlen(currentFile) - 6]) + a:i)
  let newFile = substitute(currentFile, "\\d", index, "")

  if filereadable(newFile)
    execute "edit " . newFile
  endif
endfunction

function! ankify#mappings#copy(mode)
  if a:mode == 'f'
    let @+=(b:ftag)
    return
  endif

  if match(getline('.'), '^:\d\{1,4\}\a*:$') != -1

    if a:mode == 'q'
      let @+='card:1 tag:'.(b:ftag).' Quest:"*'.(getline('.')).'*"'

    elseif a:mode == 'v'
      let l:qq='card:1 tag:'.(b:ftag).' Quest:\"*'.(getline('.')).'*\"'
      call jobstart('curl localhost:8765 -X POST -d ''{"action":"guiBrowse","version":6,"params":{"query": "'.l:qq.'"}}''')

    elseif a:mode == 'a'
      let l:view = winsaveview()
      execute 'normal! "ayip'
      call winrestview(l:view)
      jobstart('curl localhost:8765 -X POST -d ''{ "action": "guiAddCards", "version": 6, "params": {'
            \ '"note": { "deckName": "'.(g:ankify_deckName).'", "modelName": "'.(g:ankify_modelName).'",'
            \ '"fields": { "'.(g:ankify_mainField).'": "'.(@a).'"},'
            \ '"options": { "closeAfterAdding": true }, "tags": [ "'.(b:ftag).'" ] } } }')

    elseif a:mode == 't'
      let @+=(b:ftag).(getline('.'))
    endif

  else
    echomsg "Can only be executed on qtag lines!"
  endif
endfunction

function! ankify#mappings#insert(mode)
  if !empty(b:qtags_unique)
    execute 'normal! 0Di:'.(b:qtags_unique[-1] + 1).':'
  else
    execute 'normal! 0Di:1:'
  endif

  silent write
  call AdocPrintMeta()
endfunction
