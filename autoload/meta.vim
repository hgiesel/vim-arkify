"""""""""""""""""""" Pecho
let Pecho=''
function! Pecho(msg)
  let s:hold_ut=&ut | if &ut>1|let &ut=1|en
  let Pecho=a:msg
  aug Pecho
    au CursorHold * if Pecho!=''| echohl ErrorMsg | echo Pecho | echohl None
          \|let s:Pecho=''|if s:hold_ut > &ut |let &ut=s:hold_ut|en|en
        \|aug Pecho|exe 'au!'|aug END|aug! Pecho
  aug END
endfunction

"""""""""""""""""""" Print meta information """""""""""""""""""
function! meta#readme()
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
  silent write

  call winrestview(l:view)
endfunction

function! meta#leaf()
  let b:topic = expand('%:p:h:t')
  let b:file_references = []
  let b:content_lines   = 0
  let l:qtags           = []
  let l:extLines        = ''

  if expand("%:r") == 'README'
    return 5
  endif
  let l:view = winsaveview()

  """ populate qtags, extLines, content_lines
  call cursor([3,1])

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
    call Pecho('Duplicate tags: '.string(b:qtags_duplicate))
  elseif !empty(b:qtag_references_dangling)
    call Pecho('Dangling qtag references: '.string(b:qtag_references_dangling))
  elseif !empty(b:file_references_dangling)
    call Pecho('Dangling file references: '.string(b:file_references_dangling))
  else
    call Pecho('')
  endif

  call winrestview(l:view)
endfunction
