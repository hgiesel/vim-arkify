"""""""""""""""""""" Key mappings for archive """"""""""""""""""""""""

function! mappings#jumpRelative(i)
  let currentFile = expand('%:t')
  " get the number of the end of file name
  let index = string(str2nr(currentFile[strlen(currentFile) - 6]) + a:i)
  let newFile = substitute(currentFile, "\\d", index, "")

  if filereadable(newFile)
    execute "edit " . newFile
  endif
endfunction

function! mappings#copy(mode)
  if a:mode == 'f'
    let @+=(b:ftag)
    return
  endif

  if match(getline('.'), '^:\d\{1,4\}\a*:$') != -1

    if a:mode == 'q'
      let @+='card:1 tag:'.(b:ftag).' Quest:"*'.(getline('.')).'*"'

    elseif a:mode == 'v'
      let l:qq='card:1 tag:'.(b:ftag).' Quest:\"*'.(getline('.')).'*\"'

    elseif a:mode == 'b'
      execute 'normal! "ayy'
      let l:qid = substitute(@a, '.*:\([0-9]\+\):.*', '\1', '')

      let cmd = 'ark browse '.expand('%:p:h:t').'::'.expand('%:r').'#'.l:qid
      call system(cmd)

    elseif a:mode == 'a'
      let l:view = winsaveview()
      execute 'normal! "ayip'
      let l:entry = @a

      let l:qid = substitute(@a, '.*:\([0-9]\+\):.*', '\1', '')
      let l:content = substitute(@a, '.\{-}\n', '', '')

      let cmd = 'echo '''.content.''' | ark add '.expand('%:p:h:t').'::'.expand('%:r').'#'.l:qid
      call system(cmd)

      call winrestview(l:view)


    elseif a:mode == 't'
      let @+=(b:ftag).(getline('.'))
    endif

  else
    echomsg "Can only be executed on qtag lines!"
  endif
endfunction

function! mappings#insertTag(mode, length)

  let l:last_qid = system('ark stats :'.expand('%:r').' -p=none | cut -f1 | sort | tail -1')
  if l:last_qid == ''
    let l:commandv1='normal! 0Di:%0'.a:length.'d:'
    let l:commandv2=printf(l:commandv1,1)
  else
    let l:next_qid = l:last_qid + 1
    let l:commandv1='normal! 0Di:%0'.a:length.'d:'
    let l:commandv2=printf(l:commandv1,l:next_qid)
  endif

  execute l:commandv2
  write
endfunction
