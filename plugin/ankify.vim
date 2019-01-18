if exists('g:archive_options_loaded')
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

"""""""""""""""""""" Print meta information """""""""""""""""""

function! AdocPrintMetaReadme()
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

  """ write number of content lines, questions as :stats:
  call cursor([3,1])

  if b:topic == system('basename $(ARCHIVE_PATH)')
    let b:accum_content_lines = system('command grep -rPho ''(?<=\:stats\: ).*'' $(find $ARCHIVE_PATH -type f -mindepth 2 -name ''README.*'') | tail -n +2 | cut -d, -f1 | paste -sd ''+'' - | bc | tr -d ''\r\n''')
    let b:accum_qtags = system('command grep -rPho ''(?<=\:stats\: ).*'' $(find $ARCHIVE_PATH -type f -mindepth 2 -name ''README.*'') | tail -n +2 | cut -d, -f2 | paste -sd ''+'' - | bc | tr -d ''\r\n''')
  else
    let b:accum_content_lines = system('command grep --exclude README.adoc -rPho ''(?<=:stats: ).*'' | cut -d, -f1 |  paste -sd ''+'' - | bc | tr -d ''\r\n''')
    let b:accum_qtags = system('command grep --exclude README.adoc -rPho ''(?<=:stats: ).*'' | cut -d, -f2 |  paste -sd ''+'' - | bc | tr -d ''\r\n''')
  endif

  if b:accum_content_lines == ''
    silent execute 'normal! S:stats: 0,0'
  else
    silent execute 'normal! S:stats: '.b:accum_content_lines.','.b:accum_qtags
  endif


  """ save
  silent write

  call winrestview(l:view)
endfunction

function! AdocPrintMeta()
  let l:view = winsaveview()
  let b:topic = expand('%:p:h:t')

  if expand("%:r") == 'README'
    return 5
  endif

  """ populate qtags, extLines, content_lines
  call cursor([3,1])

  let l:qtags           = []
  let b:file_references = []
  let l:extLines        = ''
  let b:content_lines   = 0

  let l:moreLinesToGo = v:true

  while (l:moreLinesToGo)
    let l:currentLine = getline('.')
    call cursor([line('.')+1,1])

    if match(l:currentLine, '^:\d\{1,3\}\a*:$') != -1
      let l:qtags += [matchstr(l:currentLine, '\d\+')]
    elseif match(l:currentLine, '^:ext:\d\{1,3\}:.*$') != -1
      let l:extLines        .= l:currentLine
    elseif match(l:currentLine, '^\(include\|image\|video\)::assets\/[^/]*\[.\{-}\]$') != -1
      let b:file_references += [matchstr(l:currentLine, '^.*::\zs.*\ze[.*$')]
    elseif match(l:currentLine, '^\(\.[^. ]\+\|\.\+ .*\|\*\+ .\+\|[^''":=/\-+< ].*\)') != -1
      let b:content_lines += 1
    endif

    if line('.') == line('$')
      let l:moreLinesToGo = v:false
    endif
  endwhile

  """ populate b:qtags_duplicate and b:qtags_unique
  let b:qtags_duplicate = sort(copy(l:qtags),'N')
  let b:qtags_unique    = uniq(copy(b:qtags_duplicate))

  for i in b:qtags_unique
    call remove(b:qtags_duplicate, index(b:qtags_duplicate, i))
  endfor

  """ populate b:qtag_references
  let b:qtag_references = []

  let l:extLinesHasMoreReferences = v:true
  while l:extLinesHasMoreReferences

    let l:extReference = matchstr(l:extLines, '\d\+')

    " if no more extReferences
    if (l:extReference == '')
      let l:extLinesHasMoreReferences = v:false
    else

      let l:extLines = substitute(l:extLines, l:extReference, '', '')
      let b:qtag_references += [l:extReference]

    endif
  endwhile

  call uniq(sort(b:qtag_references))

  """ correctify b:file_references
  call uniq(sort(b:file_references))

  """ populate b:{qtag,file}_references_dangling
  let b:qtag_references_dangling = []
  let b:file_references_dangling = []

  for reference in b:qtag_references
    if index(b:qtags_unique, reference) == -1
      let b:qtag_references_dangling += [reference]
    endif
  endfor
  for reference in b:file_references
    if !filereadable(reference)
      let b:file_references_dangling += [reference]
    endif
  endfor

  """ write tag of the file as :tag:
  call cursor([2,1])
  let b:ftag = expand('%:p:h:t').'::'.expand('%:t:r')
  silent execute 'normal! S:tag: '.b:ftag

  """ write number of content lines, questions as :stats:
  call cursor([3,1])
  silent execute 'normal! S:stats: '.b:content_lines.','.len(b:qtags_unique)

  """ save
  silent write

  """ print out any errors
  """ i.e. items in b:qtags_duplicate, or dangling references
  if !empty(b:qtags_duplicate)
    call s:Pecho('Duplicate tags: '.string(b:qtags_duplicate))
  elseif !empty(b:qtag_references_dangling)
    call s:Pecho('Dangling qtag references: '.string(b:qtag_references_dangling))
  elseif !empty(b:file_references_dangling)
    call s:Pecho('Dangling file references: '.string(b:file_references_dangling))
  else
    call s:Pecho('')
  endif

  call winrestview(l:view)
endfunction

" autocmd BufWritePre *.adoc call AdocPrintMeta()
autocmd BufEnter,BufWrite *.adoc call AdocPrintMeta()
autocmd QuitPre */README.adoc call AdocPrintMetaReadme()

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

let g:archive_options_loaded = v:true
