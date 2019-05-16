"""""""""""""""""""" Key mappings for archive """"""""""""""""""""""""
function! mappings#pagerefs_insert()

  if expand('%') =~ 'README'
    let l:pageid_current = b:pageid
    let l:toc_pagerefs_cmd = "ark headings -p=id -od'|' ".(l:pageid_current)."//@:@ | head -c -1"
    let l:toc_pagerefs_output = jobstart(l:toc_pagerefs_cmd, {'on_stdout': {jobid, output, type -> mappings#pagerefs_insert2_tocs(l:pageid_current, output) }})

  else
    let l:whole_file = readfile(expand('%'))

    for elem in l:whole_file
      let l:pageid_current = b:pageid
      let findings = []
      call substitute(elem, '<<\([^>,]\+\).*>>', '\=add(l:findings, submatch(0))', 'g')

      if len(findings) > 0
        for f in findings
          let l:pageref = substitute(f, '<<!\?\([^,>]\+\).*>>', '\1', '')
          echo string(l:pageref)

          let l:pagerefs_cmd = "ark headings -p=id -d$'\n' ".(l:pageref)." | head -2 | head -c -1"
          let l:stats_output = jobstart(l:pagerefs_cmd, {'on_stdout': {jobid, output, type -> mappings#pagerefs_insert2_contentpages(l:pageid_current, output) }})
        endfor
      endif
    endfor
  endif
endfunction

function! mappings#pagerefs_insert2_tocs(pageid, input)
  if a:input[0] != '' && b:pageid == a:pageid && filereadable(expand('%:p'))
    let l:view = winsaveview()
    for elem in a:input
      let [l:pageref, l:heading, _] = split(elem, '|')
      let l:pageref = substitute(l:pageref, '^'.b:sectioncomp.'\(:.*\)', '\1', '')

      silent execute ':%s/\(<<!\?\).*'.l:pageref.',\?.\{-}>>/\1'.l:pageref.','.l:heading.'>>/'
    endfor
    call winrestview(l:view)
  endif
endfunction

function! mappings#pagerefs_insert2_contentpages(pageid, input)
  if a:input[0] != '' && b:pageid == a:pageid && filereadable(expand('%:p'))
    let l:view = winsaveview()

    let l:longid  = a:input[0]
    let l:heading = a:input[1]

    let l:used_section = substitute(l:longid, ':.*', '', '')
    let l:used_page = substitute(l:longid, '.*:', '', '')

    if l:used_section == b:sectioncomp
      silent execute ':%s/\(<<!\?\).*'.l:used_page.',\?.\{-}>>/\1:'.l:used_page.','.l:heading.'>>/'
    else
      silent execute ':%s/\(<<!\?\).*'.l:used_page.',\?.\{-}>>/\1'.l:longid.','.l:heading.'>>/'
    endif
    call winrestview(l:view)
  endif
endfunction

function! mappings#display_stats(arg)
  if a:arg[0] != '' && filereadable(expand('%:p'))
    let l:view = winsaveview()
    echo substitute(a:arg[0], '\n', '', 'g')
    call winrestview(l:view)
  endif
endfunction

function! mappings#get_stats()
  let l:stats_cmd = 'ark stats -p=id -d, :'.expand('%:r')
  let l:stats_output = jobstart(l:stats_cmd, {'on_stdout': {jobid, output, type -> mappings#display_stats(output) }})
endfunction

function! mappings#jumpRelative(i)
  let currentFile = expand('%:t')
  " get the number of the end of file name
  let index = string(str2nr(currentFile[strlen(currentFile) - 6]) + a:i)
  let newFile = substitute(currentFile, "\\d", index, "")

  if filereadable(newFile)
    execute 'edit '.newFile
  endif
endfunction

function! mappings#arkadd()
  let l:view = winsaveview()
  execute 'normal! "ayip'

  " let l:content = substitute(@a, '.\{-}\n', '', '')
  let l:content = @a
  let l:cmd = 'echo '''.content.''' | ark add '.expand('%:p:h:t').'::'.expand('%:r').' | tr -d ''\n'''
  let l:resp = system(l:cmd)

  execute 'normal! -I:' . l:resp . ':'
  call winrestview(l:view)
endfunction

function! mappings#copy(mode)
  if a:mode == 'f'
    let @+=(b:ftag)
    return
  endif

  if match(getline('.'), '^:\d\+:$') != -1

    if a:mode == 'b'
      execute 'normal! "ayy'
      let l:qid = substitute(@a, '.*:\([0-9]\+\):.*', '\1', '')

      let l:cmd = 'ark browse '.expand('%:p:h:t').'::'.expand('%:r').'#'.l:qid
      call system(l:cmd)

    elseif a:mode == 'a'
      let l:view = winsaveview()
      execute 'normal! "ayip'
      let l:entry = @a

      let l:qid = substitute(@a, '.*:\([0-9]\+\):.*', '\1', '')
      let l:content = substitute(@a, '.\{-}\n', '', '')

      let cmd = 'echo '''.content.''' | ark add '.expand('%:p:h:t').'::'.expand('%:r')
      echo system(cmd)

      call winrestview(l:view)

    endif

  else
    if a:mode == 'b'
      let cmd = 'ark browse '.expand('%:p:h:t').'::'.expand('%:r')
      call system(cmd)
    else

      echomsg "Can only be executed on qtag lines!"
    endif
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
