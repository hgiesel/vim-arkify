"""""""""""""""""""" Print meta information """""""""""""""""""
function! meta#toc_on_save()
  let l:view = winsaveview()
  let b:topic = expand("%:p:h:t")

  """ get accumulated stats of topic
  """ write tag of the file as :tag:

  if line('$') < 3
    silent execute 'normal! S'
  endif

  call cursor([1,1])
  silent execute 'normal! S= '.toupper(b:topic[0]).substitute(b:topic[1:],'-',' ',' ')

  call cursor([2,1])
  silent execute 'normal! S:tag: '.b:topic

  """ save
  " silent write

  call winrestview(l:view)
endfunction

function! meta#page_on_save()
  let l:view = winsaveview()

  let cmd = 'ark verify -p=none -d" : " :'.expand('%:r')
  " let cmd = 'echo hi'
  let output = jobstart(cmd, {'on_stdout': {jobid, output, type -> Pecho(output) }}) " append(line('.'), output) }})

  call winrestview(l:view)
endfunction

function! meta#page_on_exit()
  if filereadable(expand('%:p'))
    call cursor([2,1])
    silent execute 'normal! S:stats: '.substitute(system('ark stats -p=id -d, :'.expand('%:r')), '\n', '', 'g')
  endif
endfunction
