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
"     1	: bottom vertical (default)
"     2 : bottom horizontal
"     3 : top vertical
"     4 : top horizontal
"
" Author: Rick Howe
" Last Change: 2015/01/17
" Version: 1.0

if exists("g:loaded_perline_diff")
	finish
endif
let g:loaded_perline_diff = 1.0

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

" Highlight Group of Perline Diff Lines
if !exists("g:PLDHltGrp")
let g:PLDHltGrp = ["Search", "MatchParen"]
endif

" Layout Commands for Perline Diff Windows
let s:PLDWLCmds = [["botright new", "rightbelow new"],
			\["botright new", "rightbelow vnew"],
			\["topleft new", "rightbelow new"],
			\["topleft new", "rightbelow vnew"]]

function! s:ShowPerlineDiff(sl, el)
	let cbuf = winbufnr(0)

	" quit existing PLD windows
	if exists("t:pldiff[1]") && exists("t:pldiff[2]")
		call s:QuitPerlineDiff()
	endif

	" get and highlight lines
	if !exists("t:pldiff")
		let t:pldiff = {}
		call s:GetHighlightLines(1, a:sl, a:el)
		return
	endif
	call s:GetHighlightLines(2, a:sl, a:el)

	" calculate window width and height
	let width = (g:PLDWLType % 2) ? &columns - 2 : (&columns - 1) / 2 - 2
	let h = [0, 0]
	for k in [1, 2]
		for l in t:pldiff[k]
			let w = strdisplaywidth(l)
			let h[k - 1] += w > 0 ? (w - 1) / width + 1 : 1
		endfor
	endfor
	let height = min([max(h), &lines / ((g:PLDWLType % 2) ? 4 : 2)])

	" show PLD windows
	for k in [1, 2]
		exec s:PLDWLCmds[g:PLDWLType - 1][k - 1]
		exec "resize " . height
		call setline(1, t:pldiff[k])
		let &l:statusline = "%=%#" . g:PLDHltGrp[k - 1] .
				\"#[diff #" . k . "]%## " . len(t:pldiff[k])
		diffthis
		setlocal winfixheight nomodified nonumber wrap
		let w:pldiff = k
	endfor

	exec bufwinnr(cbuf) . "wincmd w"
endfunction

function! s:GetHighlightLines(k, sl, el)
	" get lines
	let t:pldiff[a:k] = getline(a:sl, a:el)

	" highlight lines
	if !exists("w:pldmid") | let w:pldmid = [] | endif
	let w:pldmid += [matchadd(g:PLDHltGrp[a:k - 1],
		\join(map(range(a:sl, a:el), '"\\%" . v:val . "l"'), '\|'), 0)]
endfunction

function! s:QuitPerlineDiff()
	let cbuf = winbufnr(0)

	for win in range(winnr('$'), 1, -1)
		" delete match ids
		if !empty(getwinvar(win, "pldmid", []))
			exec win . "wincmd w"
			for m in w:pldmid | call matchdelete(m) | endfor
			unlet w:pldmid
		endif

		" quit PLD window
		if getwinvar(win, "pldiff", 0)
			exec win . "wincmd w"
			quit!
		endif
	endfor

	" delete line buffers
	if exists("t:pldiff") | unlet t:pldiff | endif

	exec bufwinnr(cbuf) . "wincmd w"
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
