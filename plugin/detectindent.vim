" Name:          detectindent (global plugin)
" Version:       1.0
" Author:        Ciaran McCreesh <ciaran.mccreesh at googlemail.com>
" Updates:       http://github.com/ciaranm/detectindent
" Purpose:       Detect file indent settings
"
" License:       You may redistribute this plugin under the same terms as Vim
"                itself.
"
" Usage:         :DetectIndent
"
"                " to prefer expandtab to noexpandtab when detection is
"                " impossible:
"                :let g:detectindent_preferred_expandtab = 1
"
"                " to set a preferred indent level when detection is
"                " impossible:
"                :let g:detectindent_preferred_indent = 4
"
" Requirements:  Untested on Vim versions below 6.2

fun! <SID>IsCommentStart(line)
    " &comments isn't reliable
    if &ft == "c" || &ft == "cpp"
        return -1 != match(a:line, '/\*')
    else
        return 0
    endif
endfun

fun! <SID>IsCommentEnd(line)
    if &ft == "c" || &ft == "cpp"
        return -1 != match(a:line, '\*/')
    else
        return 0
    endif
endfun

fun! <SID>DetectIndent()
    let l:has_leading_tabs            = 0
    let l:has_leading_spaces          = 0
    let l:shortest_leading_spaces_run = 0
    let l:longest_leading_spaces_run  = 0

    let l:idx_end = line("$")
    let l:idx = 1
    while l:idx <= l:idx_end
        let l:line = getline(l:idx)

        " try to skip over comment blocks, they can give really screwy indent
        " settings in c/c++ files especially
        if <SID>IsCommentStart(l:line)
            while l:idx <= l:idx_end && ! <SID>IsCommentEnd(l:line)
                let l:idx = l:idx + 1
                let l:line = getline(l:idx)
            endwhile
            let l:idx = l:idx + 1
            continue
        endif

        let l:leading_char = strpart(l:line, 0, 1)

        if l:leading_char == "\t"
            let l:has_leading_tabs = 1

        elseif l:leading_char == " "
            " only interested if we don't have a run of spaces followed by a
            " tab.
            if -1 == match(l:line, '^ \+\t')
                let l:has_leading_spaces = 1
                let l:spaces = strlen(matchstr(l:line, '^ \+'))
                if l:shortest_leading_spaces_run == 0 ||
                            \ l:spaces < l:shortest_leading_spaces_run
                    let l:shortest_leading_spaces_run = l:spaces
                endif
                if l:spaces > l:longest_leading_spaces_run
                    let l:longest_leading_spaces_run = l:spaces
                endif
            endif

        endif

        let l:idx = l:idx + 1
    endwhile

    if l:has_leading_tabs && ! l:has_leading_spaces
        " tabs only, no spaces
        set noexpandtab
        if exists("g:detectindent_preferred_tabsize")
            let &shiftwidth  = g:detectindent_preferred_indent
            let &tabstop     = g:detectindent_preferred_indent
        endif

    elseif l:has_leading_spaces && ! l:has_leading_tabs
        " spaces only, no tabs
        set expandtab
        let &shiftwidth  = l:shortest_leading_spaces_run

    elseif l:has_leading_spaces && l:has_leading_tabs
        " spaces and tabs
        set noexpandtab
        let &shiftwidth = l:shortest_leading_spaces_run

        " mmmm, time to guess how big tabs are
        if l:longest_leading_spaces_run < 2
            let &tabstop = 2
        elseif l:longest_leading_spaces_run < 4
            let &tabstop = 4
        else
            let &tabstop = 8
        endif

    else
        " no spaces, no tabs
        if exists("g:detectindent_preferred_tabsize")
            let &shiftwidth  = g:detectindent_preferred_indent
            let &tabstop     = g:detectindent_preferred_indent
        endif
        if exists("g:detectindent_preferred_expandtab")
            set expandtab
        endif

    endif
endfun

command! -nargs=0 DetectIndent call <SID>DetectIndent()

