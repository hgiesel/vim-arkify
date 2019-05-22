
function! arkify#assets#import_from_directory()
  let l:whole_line = getline('.')

  if match(l:whole_line, '^image\:\:.*\[.*\]$') == 0
    let l:assetref_image = substitute(l:whole_line, '^image::\(.*\)\[.*\]', '\1', '')

    call s:ImportPicture(l:assetref_image)

  elseif match(l:whole_line, '^include\:\:.*\[.*\]$') == 0
    let l:assetref_include = substitute(l:whole_line, '^include::\(.*\)\[.*\]', '\1', '')

    echo 'Detected include asset '.l:assetref_include.'.'
  endif

endfunction

function! s:ImportPicture(file_name)
  let l:file_name_whole = g:arkify_import_directory . '/' . a:file_name

  if filereadable(l:file_name_whole)

    echo l:file_name_whole . ' yes!'
    let l:command_convert = 'pdftoppm -singlefile -jpegopt ''quality=50,progressive=y,optimize=y'' '''.l:file_name_whole.''' '''.a:file_name.''' -jpeg' && f
    echo system(l:command_convert)
    echo l:command_convert

  else
    echo l:file_name_whole . ' nooo!'
  endif

endfunction
