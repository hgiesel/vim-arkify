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


function! meta#print_stats(arg)

  if a:arg[0] != '' && filereadable(expand('%:p'))
    let l:view = winsaveview()
    call cursor([2,1])
    silent execute 'normal! S:stats: '.substitute(a:arg[0], '\n', '', 'g')
    noautocmd silent write
    call winrestview(l:view)
  endif
endfunction

function! meta#page_on_save()
  let l:view = winsaveview()

  let verify_cmd = 'ark verify -p=none -d" : " :'.expand('%:r')
  let verify_output = jobstart(verify_cmd, {'on_stdout': {jobid, output, type -> Pecho(output) }}) " append(line('.'), output) }})

  let stats_cmd = 'ark stats -p=id -d, :'.expand('%:r')
  let stats_output = jobstart(stats_cmd, {'on_stdout': {jobid, output, type -> meta#print_stats(output) }}) " append(line('.'), output) }})

  " let pageref_headings_cmd = 
  " nmap <silent> <Plug>(AnkifyLinksInsert) :%s/<<\([^,]*\)\%(,.*\)\?>>/\=substitute('<<'.submatch(1).','.system('ark headings -p=none '.submatch(1).'<bar>head -1<bar>cut -f1').'>>','\n','','g')<cr>

  call winrestview(l:view)
endfunction

function! meta#set_context(list)
  b:ankify_context = a:list[:-2]
endfunction

function! meta#toc_on_enter()
    call cursor([2,1])

    let context_cmd = 'ark pagerefs -p=none :'.expand('%:r').' | cut -f1' 
    let context_output = jobstart(context_cmd, {'on_stdout': {jobid, output, type -> meta#set_context(output) }}) " append(line('.'), output) }})
endfunction

function! meta#page_on_exit()
  let a = 1
endfunction
