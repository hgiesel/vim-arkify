"""""""""""""""""""" Print meta information """""""""""""""""""
function! arkify#meta#cal_on_save()
  let l:view = winsaveview()

  let l:whole_file = readfile(expand('%'))

  let l:first_entry = v:true
  let l:current_day = ''
  let l:current_day_output = ''
  let l:lineidx = 0

  for l:line in l:whole_file
    if l:line =~# '\.W\d\{2}-[1-7].*'

      if !l:first_entry
        if l:current_day_output == ''
          silent execute 'normal! '.(l:lineidx+1).'GS'.l:whole_file[l:lineidx][0:5]
        else
          silent execute 'normal! '.(l:lineidx+1).'GS'.l:whole_file[l:lineidx][0:5].' '.l:current_day_output
        endif

      endif

      let l:current_day_output = ''
      let l:current_day = l:line
      let l:lineidx = index(l:whole_file, l:line)

      let l:first_entry = v:false

    elseif !l:first_entry
      if l:line =~# '^\. .* ok$'
        let l:current_day_output .= '🔵'
      elseif l:line =~# '^\. .*$'
        let l:current_day_output .= '⚪'
      endif
    endif
  endfor

  silent write
  call winrestview(l:view)
endfunction


function! arkify#meta#toc_on_save()
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

  call winrestview(l:view)
endfunction


function! arkify#meta#prepare_stats(arg)
  if a:arg[0] != '' && filereadable(expand('%:p'))
    let l:view = winsaveview()
    let b:stats_fix_cmd = 'normal! S:stats: '.substitute(a:arg[0], '\n', '', 'g')
    call winrestview(l:view)
  endif
endfunction

function! arkify#meta#page_on_save_stats()
  let l:stats_cmd = 'ark stats -p=id -d, :'.expand('%:r')
  let l:stats_output = jobstart(l:stats_cmd, {'on_stdout': {jobid, output, type -> arkify#meta#prepare_stats(output) }}) " append(line('.'), output) }})

  if exists('b:stats_fix_cmd')
    call cursor([2,1])
    silent execute b:stats_fix_cmd
    silent noautocmd write
  endif
endfunction

function! arkify#meta#page_on_save()
  let l:view = winsaveview()

  let l:verify_cmd = 'ark verify -p=none -d" : " :'.expand('%:r')
  let l:verify_output = jobstart(l:verify_cmd, {'on_stdout': {jobid, output, type -> Pecho(output) }}) " append(line('.'), output) }})

  call winrestview(l:view)
endfunction

function! arkify#meta#search_archive()
  if exists('g:archive_root')
    if exists('g:loaded_denite')
      call denite#start([{'name': 'grep', 'args': [g:archive_root]}])
    else
      echo 'Denite is not installed'
    endif

  else
    echo 'Archive root is not set'
  endif
endfunction

function! arkify#meta#search_tocs()
    let toc_cmd = 'ark paths --tocs @:@ | head -c -1'
    let toc_output = jobstart(toc_cmd, {'on_stdout': {jobid, output, type -> arkify#meta#search_meta_search(output) }})
endfunction

function! arkify#meta#search_toc_context()
  if exists ('w:toc_current') && exists('w:toc_files')
    call arkify#meta#search_meta_search(w:toc_files)
  else
    echo 'No toc context established'
  endif
endfunction

function! arkify#meta#search_expanded_toc_context()
  if exists('w:toc_current')
    let toc_cmd = 'ark paths --expand-tocs '.w:toc_current.'//@:@ | head -c -1'
    let toc_output = jobstart(toc_cmd, {'on_stdout': {jobid, output, type -> arkify#meta#search_meta_search(output) }})
  else
    echo 'No toc context established'
  endif
endfunction

function! arkify#meta#search_meta_search(input)
  if a:input != ['']
    if len(a:input) > 0
      if exists('g:loaded_denite')
        call denite#start([{'name': 'grep', 'args': [a:input, '']}])
      else
        echo 'Denite is not installed'
      endif
    else
      echo 'No files to search were found'
    endif
  endif
endfunction

function! arkify#meta#page_go_upup()
  if exists('g:loaded_denite')
    let l:first_cmd = 'grep:.::<<!\\?\:'.b:pagecomp.',.*>>'
    let l:second_cmd = 'grep:'.g:archive_root.'::<<!\\?'.substitute(b:pageid, ':', '\\:', '').',.*>>'
    let l:full_cmd = 'Denite -no-empty ' . l:first_cmd . ' ' . l:second_cmd
    execute l:full_cmd
  else
    echo 'Command needs denite.vim to be installed'
  endif
endfunction

function! arkify#meta#page_go_up()
  if exists('w:toc_history_pagerefs') && exists('w:toc_idx')

    if len(w:toc_history_pagerefs) == 0
      echo 'No toc context available'
      return
    end

    " Remove one layer preemptively if you're going up in toc itself
    if b:pageid == w:toc_history_pagerefs[-1]
      call remove(w:toc_history_files, -1)
      call remove(w:toc_history_pagerefs, -1)
    endif

    if len(w:toc_history_pagerefs) == 0
      echo 'No toc context available'
      return
    end

    let l:upfile = w:toc_history_files[-1]

    if filereadable(l:upfile)
      let b:going_up = v:true

      if w:toc_idx != -1
        silent execute 'edit +normal!\ G'.w:toc_linenos[w:toc_idx].'zz '.l:upfile
      else
        silent execute 'edit '.l:upfile
      end

      call remove(w:toc_history_files, -1)
      call remove(w:toc_history_pagerefs, -1)

    else
      echo 'Toc is not readable: '.l:upfile
    endif
  endif
endfunction


function! arkify#meta#page_go_rel(rel)
  if exists('w:toc_files') && exists('w:toc_idx') && w:toc_idx != -1 

    let b:going_rel = v:true
    let l:relfile = get(w:toc_files, w:toc_idx + a:rel, w:toc_files[0])

    if filereadable(l:relfile)
      silent execute 'edit '.l:relfile
    else
      echo 'File is not readable: '.l:relfile
    endif

  endif
endfunction

function! arkify#meta#page_on_enter()
  let b:going_up = v:false
  let b:going_rel = v:false

  let b:sectioncomp = expand('%:p:h:t')
  let b:pagecomp    = expand('%:p:t:r')
  let b:pageid      = (b:sectioncomp).':'.(b:pagecomp)

  " cut off newline character
  if ! exists('g:archive_root')
    let g:archive_root = system('ark paths')[0:-2]
  endif

  if exists('w:toc_pagerefs')
    let w:toc_idx = index(w:toc_pagerefs, b:pageid)
  endif

  if exists('b:stats_fix_cmd')
    unlet b:stats_fix_cmd
  endif
endfunction

function! arkify#meta#page_on_leave()
endfunction

function! arkify#meta#toc_on_enter()
  let b:going_up  = v:false
  let b:going_rel = v:false

  let b:sectioncomp = expand('%:p:h:t')
  let b:pagecomp    = expand('%:p:t:r')
  let b:pageid      = (b:sectioncomp).':'.(b:pagecomp)

  " cut off newline character
  if ! exists('g:archive_root')
    let g:archive_root = system('ark paths')[0:-2]
  endif

  if ! exists('w:toc_history_files')
    let w:toc_history_files = []
    let w:toc_history_pagerefs = []

    let context_cmd = 'ark pagerefs -p=none -d, '.b:pageid.' | head -c -1'
    let context_output = jobstart(context_cmd, {'on_stdout': {jobid, output, type -> arkify#meta#set_context(output) }})

    let w:toc_current = b:pageid

  endif

  if exists('w:toc_pagerefs')
    let w:toc_idx = index(w:toc_pagerefs, b:pageid)
  endif
endfunction

function! arkify#meta#toc_on_leave_wrapper()
  let l:ark_uri = substitute(getline('.'), '.*<<!\?\([^<,>]*\).*', '\1', '')

  " if you're on a readme file, follow it
  if l:ark_uri =~ 'README'
    call arkify#meta#follow_link(l:ark_uri)
  endif

  " otherwise set toc context to current file, if readme
  if expand('%') =~ 'README'
    call arkify#meta#toc_on_leave()
  else
    echo 'Can only be executed in tocs'
  endif
endfunction

function! arkify#meta#toc_on_leave()
  " only add to toc_history if you don't leave the current toc_history +
  " you're not going rel or up
  if exists('w:toc_history_pagerefs') && exists('w:toc_history_files')
        \ && (get(w:toc_history_pagerefs, -1, '') != b:pageid) && ! b:going_up && ! b:going_rel
    call add(w:toc_history_pagerefs, b:pageid)
    call add(w:toc_history_files, expand('%:p'))
  endif

  if ! b:going_up && ! b:going_rel
    let context_cmd = 'ark pagerefs -p=none -d, '.b:pageid.' | head -c -1'
    let context_output = jobstart(context_cmd, {'on_stdout': {jobid, output, type -> arkify#meta#set_context(output) }})

    let w:toc_current = b:pageid
  endif
endfunction

function! arkify#meta#set_context(list)
  if a:list != ['']
    let w:toc_pagerefs = []
    let w:toc_linenos = []
    let w:toc_files = []

    for elem in a:list
      let [l:pageref, l:lineno, l:file] = split(elem, ',')

      call add(w:toc_pagerefs, l:pageref)
      call add(w:toc_linenos, l:lineno+1)
      call add(w:toc_files, l:file)
    endfor

    let w:toc_idx = index(w:toc_pagerefs, b:pageid)
  endif
endfunction

function! arkify#meta#follow_link_with_current_line()
  let l:line_current = getline('.')
  let l:pageref = substitute(l:line_current, '.*<<!\?\([^<,>]*\).*', '\1', '')


  if l:line_current == l:pageref
    echom 'No pageref found on current line: '.line('.').'!'
  else

    if l:pageref[0] == ':'
      let l:pageref = expand('%:p:h:t').l:pageref
    endif

    call arkify#meta#follow_link(l:pageref)
  end
endfunction

" Pressing Qf in file, or :Ark
function! arkify#meta#follow_link(pageref)
  if a:pageref[0] == ':'
    " I can guess the link if it starts with colon
    execute 'edit ./'.a:pageref[1:-1].'.*'

  elseif exists('w:toc_current') && exists('w:toc_pagerefs') && index(w:toc_pagerefs, a:pageref) != -1
    " The link is part of the toc context
    execute 'edit '.w:toc_files[index(w:toc_pagerefs, a:pageref)]

  else
    " Otherwise I have to process it
    " also the only path that allows noteids instead of pageids
    let l:path = system("ark paths '".a:pageref."'")[0:-2] " skip newline at the end

    if l:path[-1:] == ':'
      " if pageref contained a noteid
      let l:cmd_pre = '+silent\ execute\ ''normal!\ '
      let l:cmd_post = 'GzMzv'''

      let l:path_actual = substitute(l:path, '\(.*\):\%(\d*\):', '\1', '')
      let l:lineno = substitute(l:path, '\%(.*\):\(\d*\):', '\1', '')

      let l:path_cmd = 'edit '.l:cmd_pre.l:lineno.l:cmd_post.' '.l:path_actual
    else
      let l:path_cmd = 'edit '.l:path
    end

    execute l:path_cmd
  end
  normal! 
endfunction

function! arkify#meta#copy_link_with_current_line()
  let l:line_current = getline('.')
  let l:pageref = substitute(l:line_current, '.*<<!\?\([^<,>]*\).*', '\1', '')

  if l:line_current == l:pageref
    echom 'No pageref found on current line: '.line('.').'!'
  else

    if l:pageref[0] == ':'
      let l:pageref = expand('%:p:h:t').l:pageref
    endif

    call system('echo ''<<'.l:pageref.'>>'' | pbcopy')
  end
endfunction
