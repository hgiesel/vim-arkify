
function! arkify#assets#import_from_directory()
  let l:whole_line = getline('.')

  if match(l:whole_line, '^image\:\:.*\[.*\]$') == 0
    let l:assetref_image = substitute(l:whole_line, '^image::\(.*\)\[.*\]', '\1', '')
    call s:ImportPicture(l:assetref_image)

  elseif match(l:whole_line, '^include\:\:.*\[.*\]$') == 0
    let l:assetref_include = substitute(l:whole_line, '^include::\(.*\)\[.*\]', '\1', '')
    call s:CreateAsset(l:assetref_include)

    echo 'Detected include asset '.l:assetref_include.'.'
  endif

endfunction

function! s:ImportPicture(file_name)
  let l:file_ext = substitute(a:file_name, '.*\.\(.*\)', '\1', '')

  let l:file_source = g:arkify_import_directory . '/' . a:file_name
  let l:file_source_with_pdf = substitute(l:file_source, '\(.*\)\.'.l:file_ext, '\1.pdf', '')

  " no ext on the file destination
  let l:file_destination = expand('%:p:h') . '/assets/' . a:file_name[0:-5]

  if !filereadable(l:file_source_with_pdf)
    echom 'File cannot be imported because it does not exist: "'l:file_source_with_pdf.'"!'

  elseif filereadable(l:file_destination.'.'.l:file_ext)
    echom 'File already exists: "'.l:file_destination.'.'.l:file_ext.'"!'

  else
    let l:command_convert = 'pdftoppm -singlefile -jpegopt ''quality=50,progressive=y,optimize=y'' '''.l:file_source_with_pdf.''' '''.l:file_destination.''' -jpeg'
    call system(l:command_convert)

    if filereadable(l:file_destination)
      echo 'Picture was imported successfully!'
      call delete(l:file_destination)
    else
      echoerr 'Picture could not be imported!'
    endif
  endif
endfunction

function! s:CreateAsset(file_name)
  let l:file_destination = expand('%:p:h') . '/assets/' . a:file_name

  if filereadable(l:file_destination)
    echom 'File already exists: "'.l:file_destination.'"!'

  else
    execute 'edit '.l:file_destination

    if filereadable(l:file_destination)
      echo 'File was created successfully!'
    endif
  endif

endfunction
