" perline-diff.vim - this line, that line, then diff comes up
"
" You can see the differences between any lines displayed on the vim.
"
" It is handy and simple. Press <F9> on a line in some window, and press <F9>
" again on another line in same or different window, then horizontally
" separated two tiny windows come up at the bottom of this page and shows
" those differences. Selected each lines are differently highlighted on their
" window. To return back to the original screen, just press <F10>.
"
" You can select a block of lines by pressing <F9> in visual mode or by using
" SPLDiff command with range. If prefer to see those diff windows at top
" and/or in vertical, use g:PLDWLType global variable. <F9> and <F10> keys
" are configurable as well.
"
" If diffchar.vim plugin has been installed, you can see the exact differences
" on both the perline diff windows.
"
" Commands
" :[range]SPLDiff - select lines and show those diff windows
" :QPLDiff - quit the perline diff windows
"
" Configurable keymaps
" <Plug>ShowPerlineDiff (default: <F9>)
" <Plug>QuitPerlineDiff (default: <F10>)
"
" Global variables
" g:PLDWLType - layout type of perline diff windows
"     1 : bottom horizontal (default)
"     2 : bottom vertical
"     3 : top horizontal
"     4 : top vertical
"
" Author: Rick Howe
" Last Change: 2015/10/07
" Version: 1.2
"
" Update 1.2
" * Fixed to restore the size of existing windows after closing perline diff
"   windows.
" * Fixed to show the exact difference with diffchar.vim 5.3 and later.
"
" Update 1.1
" * If an original window has been in diff mode, temporary clear its diff mode
"   while displaying perline diff windows.
" * If the selected lines are moved on the original window, their highlights
"   will also follow those lines.
" * Adjust height of perline diff windows to show just as many selected lines
"   as possible including diff filler lines, within the half of vim's height.

if exists("g:loaded_perline_diff")
	finish
endif
let g:loaded_perline_diff = 1.1

let s:save_cpo = &cpo
set cpo&vim

command! -range SPLDiff call s:ShowPerlineDiff(<line1>, <line2>)
command! QPLDiff call s:QuitPerlineDiff()

noremap <silent> <Plug>ShowPerlineDiff :SPLDiff<CR>
noremap <silent> <Plug>QuitPerlineDiff :QPLDiff<CR>
if !hasmapto('<Plug>ShowPerlineDiff')
	map <silent> <F9> <Plug>ShowPerlineDiff
endif
if !hasmapto('<Plug>QuitPerlineDiff')
	map <silent> <F10> <Plug>QuitPerlineDiff
endif

" Layout Type of Perline Diff Windows
if !exists("g:PLDWLType")
let g:PLDWLType= 1	" bottom horizontal
" let g:PLDWLType= 2	" bottom vertical
" let g:PLDWLType= 3	" top horizontal
" let g:PLDWLType= 4	" top vertical
endif

" Temporary clear diff mode on existing windows
if !exists("g:PLDCDMode")
let g:PLDCDMode = 1	" enable
" let g:PLDCDMode = 0	" disable
endif

" Highlight Group of Perline Diff Lines
if !exists("g:PLDHltGrp")
let g:PLDHltGrp = ["Search", "MatchParen"]
endif

" Layout Commands for Perline Diff Windows
let s:PLDWLCmds = [["botright 1new", "rightbelow 1new"],
			\["botright 1new", "rightbelow vnew"],
			\["topleft 1new", "rightbelow 1new"],
			\["topleft 1new", "rightbelow vnew"]]

function! s:ShowPerlineDiff(sl, el)
	" reset if both PLD windows exist
	if exists("t:pld_lines[1]") && exists("t:pld_lines[2]")
		call s:QuitPerlineDiff()
	endif

	" clear all diff mode on existing windows or return
	for win in range(1, winnr('$'))
		if getwinvar(win, "&diff")
			if g:PLDCDMode
				call setwinvar(win, "&diff", 0)
				call setwinvar(win, "pld_diffed", 1)
				if exists("g:loaded_diffchar")
					%RDChar
				endif
			else
				echo "a diff mode window already exists!"
				return
			endif
		endif
	endfor
	
	" get and highlight selected lines
	if !exists("t:pld_lines")
		let t:pld_lines = {}
		call s:GetHighlightLines(1, a:sl, a:el)
		return
	endif
	call s:GetHighlightLines(2, a:sl, a:el)

	" save a command to restore the size of existing windows
	let s:restcmd = winrestcmd()

	let cbuf = winbufnr(0)

	" open PLD windows and set options and lines
	let wn = {}
	for k in [1, 2]
		exec s:PLDWLCmds[g:PLDWLType - 1][k - 1]
		let wn[k] = winnr()
		let w:pld_winid = k
		let &l:scrollbind = 1
		let &l:winfixheight = 1
		let &l:modified = 0
		let &l:statusline = "%=%#" . g:PLDHltGrp[k - 1] . "#[diff #" .
					\k . "]%## " . len(t:pld_lines[k])
		call setline(1, t:pld_lines[k])
		let &l:diff = 1
	endfor

	" adjust window hights
	let h = {}
	for k in [1, 2]
		exec wn[k] . "wincmd w"
		let h[k] = -1
		let ww = winwidth(0)
		for n in range(1, line('$') + 1)
			let lw = strdisplaywidth(getline(n))
			let h[k] += (lw > 0 ? (lw - 1) / ww + 1 : 1) +
							\diff_filler(n)
		endfor
	endfor
	let wh = min([max(values(h)), max([float2nr(round((&lines - &cmdheight)
			\/ (g:PLDWLType % 2 ? 4.0 : 2.0))) - 1, 1])])
	exec wn[1] . "resize " . wh
	exec wn[2] . "resize " . wh

	exec bufwinnr(cbuf) . "wincmd w"
endfunction

let s:plmark = ['i', 'j', 'k', 'l']

function! s:GetHighlightLines(k, sl, el)
	" get lines
	let t:pld_lines[a:k] = getline(a:sl, a:el)

	" highlight lines
	if !exists("w:pld_hlmid") | let w:pld_hlmid = [] | endif
	let [sm, em] = s:plmark[(a:k - 1) * 2 : (a:k - 1) * 2 + 1]
	exec a:sl . "mark " . sm | exec a:el . "mark " . em
	let w:pld_hlmid += [matchadd(g:PLDHltGrp[a:k - 1], (a:sl == a:el ?
		\"" : "^.*\\%>'" . sm . ".*\\%<'" . em . ".*$\\|") .
			\"^.*\\%'" . em . ".*$", 0)]
endfunction

function! s:QuitPerlineDiff()
	let cbuf = winbufnr(0)

	" quit all PLD windows
	for win in range(winnr('$'), 1, -1)
		if getwinvar(win, "pld_winid", 0)
			exec win . "wincmd w"
			quit!
		endif
	endfor

	for win in range(1, winnr('$'))
		" delete highlight match ids
		if !empty(getwinvar(win, "pld_hlmid", []))
			exec win . "wincmd w"
			for m in w:pld_hlmid | call matchdelete(m) | endfor
			unlet w:pld_hlmid
			exec "delmarks " join(s:plmark)
		endif

		" restore diff mode on original diff mode windows
		if getwinvar(win, "pld_diffed", 0)
			call setwinvar(win, "&diff", 1)
			call setwinvar(win, "pld_diffed", 0)
		endif
	endfor

	" delete line buffer
	if exists("t:pld_lines") | unlet t:pld_lines | endif

	exec bufwinnr(cbuf) . "wincmd w"

	" restore the size of existing windows
	exec s:restcmd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
