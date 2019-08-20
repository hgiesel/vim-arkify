if exists('g:ankify_vim_loaded')
  finish
endif
let s:plugindir = expand('<sfile>:p:h:h')

let g:Pecho=[]

if !exists('g:arkify_import_directory')
  let g:arkify_import_directory = '/Users/hgiesel/Library/Mobile Documents/iCloud~net~doo~scanbot/Documents'
endif

function! Recho()
  let g:Pecho = []
endfunction

function! Pecho(msg)
  for msgitem in a:msg
    if index(g:Pecho, msgitem) == -1 && msgitem != ''
      let g:Pecho+=a:msg
    endif
  endfor
endfunction

autocmd BufWritePost * if g:Pecho != []
      \| echohl ErrorMsg
      \| for mes in g:Pecho | echo mes | endfor
      \| echohl None
      \| let g:Pecho=[]
      \| endif

" PLUG COMMANDS; PAGEREFS {{{2
nmap <silent> <localleader>] <Plug>(ArkifyNextFile)
nmap <silent> <localleader>[ <Plug>(ArkifyPrevFile)
nmap <silent> <localleader>u <Plug>(ArkifyUpFile)
nmap <silent> <localleader>U <Plug>(ArkifyUpUpFile)

nmap <silent> <Plug>(ArkifyNextFile) :call arkify#meta#page_go_rel(1)<cr>
nmap <silent> <Plug>(ArkifyPrevFile) :call arkify#meta#page_go_rel(-1)<cr>
nmap <silent> <Plug>(ArkifyUpFile)   :call arkify#meta#page_go_up()<cr>
nmap <silent> <Plug>(ArkifyUpUpFile) :call arkify#meta#page_go_upup()<cr>

nmap <silent> <localleader>i <Plug>(ArkifyInsertHash)
nmap <silent> <localleader>n <Plug>(ArkifyNewPage)
nmap <silent> <localleader>= <Plug>(ArkifyLinksInsert)
nmap <silent> <localleader>+ <Plug>(ArkifyLinksClear)

nmap <silent> <localleader>f <Plug>(ArkifyLinksFollow)
nmap <silent> <localleader>F <Plug>(ArkifyLinksSetContext)
nmap <silent> <localleader>g <Plug>(ArkifyLinksCopy)

nmap <silent> <Plug>(ArkifyInsertHash)      :.!grand 8<cr>
nmap <silent> <Plug>(ArkifyNewPage)         :.! read b; touch "$b".adoc; echo ". <<:$b,>>"<cr>
nmap <silent> <Plug>(ArkifyLinksInsert)     :call arkify#mappings#pagerefs_insert()<cr>
nmap <silent> <Plug>(ArkifyLinksClear)      :%s/<<\(!\?[^>,]\+\).*>>/\=substitute('<<'.submatch(1).'>>','\n','','g')<cr>

nmap <silent> <Plug>(ArkifyLinksFollow)     :call arkify#meta#follow_link_with_current_line()<cr>
nmap <silent> <Plug>(ArkifyLinksSetContext) :call arkify#meta#toc_on_leave_wrapper()<cr>
nmap <silent> <Plug>(ArkifyLinksCopy)       :call arkify#meta#copy_link_with_current_line()<cr>

" PLUG COMMANDS; ASSETREFS {{{2
nmap <silent> <localleader>I <Plug>(ArkifyImportAsset)

nmap <silent> <Plug>(ArkifyImportAsset) :call arkify#assets#import_from_directory()<cr>

" PLUG COMMANDS; SEARCHING {{{2
nmap <silent> <localleader>/a <Plug>(ArkifySearchArchive)
nmap <silent> <localleader>/t <Plug>(ArkifySearchTocs)
nmap <silent> <localleader>/c <Plug>(ArkifySearchTocContext)
nmap <silent> <localleader>/C <Plug>(ArkifySearchExpandedTocContext)

nmap <silent> <Plug>(ArkifySearchArchive)            :call arkify#meta#search_archive()<cr>
nmap <silent> <Plug>(ArkifySearchTocs)               :call arkify#meta#search_tocs()<cr>
nmap <silent> <Plug>(ArkifySearchTocContext)         :call arkify#meta#search_toc_context()<cr>
nmap <silent> <Plug>(ArkifySearchExpandedTocContext) :call arkify#meta#search_expanded_toc_context()<cr>

" PLUG COMMANDS; NOTE CREATION AND BROWSING {{{2
nmap <silent> <Plug>(ArkifyDisplayStats) :call arkify#mappings#get_stats()<cr>
nmap <silent> <Plug>(ArkifyAnkiAddCard)  :call arkify#mappings#arkadd()<cr>
nmap <silent> <Plug>(ArkifyAnkiBrowse)   :call arkify#mappings#copy('b')<cr>

nmap <silent> <localleader>s <Plug>(ArkifyDisplayStats)
nmap <silent> <localleader>a <Plug>(ArkifyAnkiAddCard)
nmap <silent> <localleader>b <Plug>(ArkifyAnkiBrowse)

" AUTO COMMANDS {{{2
" TODO should be configurable on what tags should look like
" a: count up
" b: count up (n characters long)
" c: random number (n characters long)

" autocmd BufWritePre *.* call ArkifyPrintMeta()

autocmd BufWrite $ARCHIVE_ROOT/*.adoc call arkify#meta#page_on_save()
" autocmd QuitPre $ARCHIVE_ROOT/* call arkify#meta#page_on_exit()

autocmd BufWritePost $ARCHIVE_ROOT/calendar/*.adoc call arkify#meta#cal_on_save()
autocmd BufEnter $ARCHIVE_ROOT/calendar/*.adoc call arkify#meta#cal_on_save()

autocmd BufEnter $ARCHIVE_ROOT/**/README*.adoc call arkify#meta#toc_on_enter()
autocmd BufEnter $ARCHIVE_ROOT/*.adoc call arkify#meta#page_on_enter()

autocmd BufLeave $ARCHIVE_ROOT/**/README*.adoc call arkify#meta#toc_on_leave()
autocmd BufLeave $ARCHIVE_ROOT/*.adoc call arkify#meta#page_on_leave()

command! -nargs=1 Ark call arkify#meta#follow_link("<args>")

let g:ankify_vim_loaded = v:true
