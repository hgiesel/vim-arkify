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
  let b:pageid =  expand('%:p:h:t').':'.expand('%:r')

  let l:verify_cmd = 'ark verify -p=none -d" : " :'.expand('%:r')
  let l:verify_output = jobstart(l:verify_cmd, {'on_stdout': {jobid, output, type -> Pecho(output) }}) " append(line('.'), output) }})

  let l:stats_cmd = 'ark stats -p=id -d, :'.expand('%:r')
  let l:stats_output = jobstart(l:stats_cmd, {'on_stdout': {jobid, output, type -> meta#print_stats(output) }}) " append(line('.'), output) }})

  " let pageref_headings_cmd = 
  " nmap <silent> <Plug>(AnkifyLinksInsert) :%s/<<\([^,]*\)\%(,.*\)\?>>/\=substitute('<<'.submatch(1).','.system('ark headings -p=none '.submatch(1).'<bar>head -1<bar>cut -f1').'>>','\n','','g')<cr>

  call winrestview(l:view)
endfunction

function! meta#page_go_up()
  if exists('g:toc_up') && len(g:toc_up) > 0
    let l:upfile = remove (g:toc_up, -1)

    let l:file = system('ark paths '.l:upfile)
  endif

  if exists('l:file') && filereadable(l:file) != 1
    let b:going_up = v:true
    let l:idx = index(g:toc_context, b:pageid)

    if l:idx != -1
      silent execute 'edit +normal!\ G'.g:toc_linenos[l:idx].'zz '.l:file
    else
      silent execute 'edit '.l:file
    end

  elseif exists('l:file')
    echo 'This toc is not readable: '.l:file
  else
    echo 'No toc available'
  endif
endfunction

function! meta#page_go_rel(rel)
  if exists('g:toc_context')
    let l:idx = index(g:toc_context, b:pageid)
  endif

  if exists('l:idx') && l:idx != -1 
    let b:going_rel = v:true

    let l:relid = get(g:toc_context, l:idx + a:rel, g:toc_context[0])
    let l:relfile = system('ark paths '.l:relid)
    if filereadable(l:relfile) != 1
      silent execute 'edit '.l:relfile
    endif
  elseif exists('l:idx')
    echo 'File is not within toc context'
  else
    echo 'No toc context'
  endif
endfunction

function! meta#page_on_enter()
  let b:pageid =  expand('%:p:h:t').':'.expand('%:r')
endfunction

function! meta#toc_on_enter()
  let b:current_toc = expand('%:p:h:t').':'.expand('%:t:r')

  if !exists('g:toc_up')
    let g:toc_up = []
  endif
endfunction

function! meta#set_context(list)
  if a:list != ['']
    let g:toc_context = []
    let g:toc_linenos = []
    for elem in a:list
      let [l:file, l:lineno] = split(elem, ',')
      call add(g:toc_context, l:file)
      call add(g:toc_linenos, l:lineno + 1)
    endfor
  endif
endfunction

function! meta#toc_on_leave()
  if (get(g:toc_up, -1, '') != b:current_toc) && ! exists('b:going_up') && ! exists('b:going_rel')
    call add(g:toc_up, expand('%:p:h:t').':'.expand('%:r'))
  endif

  if ! exists('b:going_up') && ! exists('b:going_rel')
    let context_cmd = 'ark pagerefs -p=none -d, :'.expand('%:r').' | head -c -1'
    let context_output = jobstart(context_cmd, {'on_stdout': {jobid, output, type -> meta#set_context(output) }})
  endif
endfunction

function! meta#page_on_leave()
  let l:a = 1
endfunction
