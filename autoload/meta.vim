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
  if expand("%:r") == 'README'
    return 5
  endif
  let l:view = winsaveview()

  """ write number of content lines, questions as :stats:
  " call cursor([2,1])
  " silent execute 'normal! S:stats: '.system('ark stats -p=none -d, :'.expand("%:r")).'dd'

  """ print out any errors
  " let output = system('ark verify -p=none -d" : " :'.expand("%:r"))

  let cmd = 'ark verify -p=none -d" : " :'.expand("%:r")
  " let cmd = 'echo hi'
  let output = jobstart(cmd, {'on_stdout': {jobid, output, type -> Pecho(output) }}) " append(line('.'), output) }})

  call winrestview(l:view)
endfunction

function! meta#page_on_exit()
  return 0
endfunction
