" ==============================================================================
" Important functions
" ==============================================================================
" Set variables on file load {{{1
let g:filetree = {}
let g:filetree.icon_type = 'filled' " Can be 'filled', 'outline', 'unicode', or 'text'
let g:filetree.indent_marker = '│ ' " The marker to show the change in level between files
let g:filetree.buffer_name = '__filetree__' " The stored name of the filetree buffer
let g:filetree.buffer_size = 35 " The width of the filetree buffer
let g:filetree.buffer_position = 'left' " The side of the screen for the filetree to be on

let s:script_path = expand("<sfile>:p")
let s:plugin_path = expand("<sfile>:p:h:h")
" }}}

" FUNCTION: filetree#Initialize() {{{1
function! filetree#Initialize()
	" Call other initialization functions
	if !exists("s:filetree_open")
		let s:filetree_open = 1
		call s:InitializeVariables()
		call s:InitializeIcons()
	endif

	call s:InitializeBuffer()
	call s:InitializeMappings()

	" Generate the starting tree
	let s:tree = s:GenerateTree(getcwd(), 0) " Stores a list of file/level pairs, representing each files distance from the root directory

	" Draw the filetree to the screen
	call s:Print()
endfunction

" }}}
" FUNCTION: s:InitializeBuffer() {{{1
function! s:InitializeBuffer()
	let window_number = bufwinnr(g:filetree.buffer_name)
	if window_number == -1 " If the sidebar isn't open, create a new split and open it
		silent! exec "vnew " . g:filetree.buffer_name

	else " If the sidebar is open, navigate to it
		exec window_number . "wincmd w"
	endif

	" Move buffer to far side of screen
	exec "wincmd " . (g:filetree.buffer_position == "left" ? "H" : "L")
	exec "vertical resize" . g:filetree.buffer_size

	" Set settings in case they aren't already
	let &buftype = "nofile"
	setlocal nobuflisted
	setlocal hidden
	setlocal nonumber
	setlocal nomodifiable
	setlocal foldmethod=manual
	setlocal nolist
	setlocal nowrap
	setlocal winfixheight
	setlocal winfixwidth
endfunction
" }}}
" FUNCTION: s:InitializeVariables() {{{1
function! s:InitializeVariables()
	let s:pwd = getcwd()
	let s:opendirs = [] " Stores a list of paths representing directories for which the contents should be displayed in the tree
	let s:show_hidden = 0 " Boolean representing whether hidden files should be shown in the tree
	let s:first_line = 2 " First line of tree after any heading text
	let s:indent_marker = "│ "
endfunction
" }}}
" FUNCTION: s:InitializeMappings() {{{1
function! s:InitializeMappings()
	let mappings = {}

	let mappings["<CR>"] = "Edit()"
	let mappings["."] = "ShowHidden(-1)"
	let mappings.v = "ShowInfo()"

	let mappings["<Space>"] = "Open()"
	let mappings.o = "OpenAll()"
	let mappings.O = "CloseAll()"

	let mappings.r  = "Reload()"
	let mappings.k  = "Scroll('up')"
	let mappings.j  = "Scroll('down')"
	let mappings.h  = "DirMove('up')"
	let mappings.l  = "DirMove('down')"
	let mappings.H  = "DirShift('up')"
	let mappings.L  = "DirShift('down')"

	let mappings["~"] = "NavigateTo('~')"
	let mappings.th = "NavigateTo('~')"
	let mappings.tr = "NavigateTo('/')"
	let mappings.u = "NavigateTo('..')"

	let mappings.a  = "AddFile(' ')"
	let mappings.af = "AddFile('f')"
	let mappings.ad = "AddFile('d')"

	let mappings.fx = "SetExecutable(-1)"
	let mappings.fd = "DeleteFile()"
	let mappings.fr = "RenameFile()"
	let mappings.fm = "MoveFile('move')"
	let mappings.fc = "MoveFile('copy')"
	let mappings.fl = "MoveFile('link')"

	let mappings.ga = "GitCmd('add')"
	let mappings.gc = "GitCmd('commit')"
	let mappings.gC = "GitCmd('ammend')"
	let mappings.gl = "GitCmd('log')"

	silent map clear
	for q in keys(mappings)
		exec "nnoremap <buffer> <silent> " . q . " :call filetree#" . mappings[q] . "<CR>"
	endfor
endfunction
" }}}
" FUNCTION: s:InitializeIcons() {{{1
function! s:InitializeIcons()
	let s:icons = {}

	let filetypes = []
	call add(filetypes, {"type":"archive", "unicode":"🖹", "outline":"", "filled":"", "extensions":["tar", "zip", "gz", "xz", "bz2"]})
	call add(filetypes, {"type":"text",    "unicode":"🖹", "outline":"", "filled":"", "extensions":["txt", "doc", "docx"]})
	call add(filetypes, {"type":"image",   "unicode":"🖻", "outline":"", "filled":"", "extensions":["png", "jpg", "jpeg", "gif"]})
	call add(filetypes, {"type":"video",   "unicode":"⏵", "outline":"", "filled":"", "extensions":["mp4", "mov", "wmv", "webm"]})
	call add(filetypes, {"type":"audio",   "unicode":"𝅘𝅥𝅮", "outline":"", "filled":"", "extensions":["mp3", "wav", "flac"]})
	call add(filetypes, {"type":"code",    "unicode":"🖹", "outline":"", "filled":"", "extensions":["exe", "AppImage", "java", "py", "c", "js", "sh", "bash", "zsh", "fish"]})
	call add(filetypes, {"type":"pdf",     "unicode":"🖹", "outline":"", "filled":"", "extensions":["pdf"]})
	call add(filetypes, {"type":"vim",     "unicode":"🖹", "outline":"", "filled":"", "extensions":["vim"]})

	if g:filetree.icon_type == "filled" || g:filetree.icon_type == "outline" || g:filetree.icon_type == "unicode"
		for q in filetypes
			for r in q.extensions
				let s:icons["e_" . r] = q[g:filetree.icon_type]
			endfor
		endfor
	endif

	let file_categories = []
	call add(file_categories, {"type":"dir",      "text":"d", "unicode":"🖿", "outline":"", "filled":""})
	call add(file_categories, {"type":"dirlink",  "text":"@", "unicode":"@", "outline":"", "filled":""})
	call add(file_categories, {"type":"file",     "text":"f", "unicode":"🖹", "outline":"", "filled":""})
	call add(file_categories, {"type":"link",     "text":"@", "unicode":"@", "outline":"", "filled":""})
	call add(file_categories, {"type":"hidden",   "text":"f", "unicode":"🖹", "outline":"﬒", "filled":"﬒"})
	call add(file_categories, {"type":"closed",   "text":">", "unicode":"▸", "outline":"▸", "filled":"▸"})
	call add(file_categories, {"type":"open",     "text":"v", "unicode":"▾", "outline":"▾", "filled":"▾"})
	call add(file_categories, {"type":"redirect", "text":">", "unicode":"➝", "outline":">", "filled":">"})

	for q in file_categories
		let s:icons["f_" . q.type] = q[g:filetree.icon_type]
	endfor

	" Git icons
	let git_options = []
	call add(git_options, {"type":"committed", "text":"*", "unicode":"✓", "outline":"✓", "filled":"✓"})
	call add(git_options, {"type":"added",     "text":"+", "unicode":"+", "outline":"✚", "filled":"✚"})
	call add(git_options, {"type":"modified",  "text":"x", "unicode":"×", "outline":"✗", "filled":"✗"})

	for q in git_options
		let s:icons["g_" . q.type] = q[g:filetree.icon_type]
	endfor

	let g:filetree_icons = s:icons
endfunction
" }}}

" FUNCTION: s:GetText() {{{1
function! s:GetText()
	" Get the longest version of the heading that will fit in the window
	if s:pwd == "/"
		let heading = "/"
	else
		let heading = s:pwd . "/"
	endif

	if len(heading) > winwidth(0)
		let heading = substitute(s:pwd, $HOME, "~", "") . "/"

		if len(heading) > winwidth(0)
			let heading = s:GetShortPath(s:pwd) . "/"
			if len(heading) > winwidth(0)
				let heading = split(s:pwd, "/")[-1] . "/"
			endif
		endif
	endif

	" Convert the tree list into a formatted string with line breaks and indents
	let output = [heading]

	for q in s:tree
		if s:show_hidden == 0 && s:IsHidden(q.path)
			continue
		endif

		let indent = repeat(s:indent_marker, q.level + 1)

		call add(output, indent . q.start . " " . q.name . q.link . q.end)
	endfor

	return output
endfunction

" }}}
" FUNCTION: s:Print() {{{1
function! s:Print()
	setlocal modifiable

	" Generate the text
	let text = s:GetText()

	" Save cursor location before redraw
	let cursor_location = [line("."), col(".")]

	" Replace all current text with new text
	silent exec "0," . line("$") . "delete"
	for q in text
		put =q
	endfor
	silent 1delete

	" Move cursor up and down file to load colors
	norm! gg
	exec "norm! " . line("$") . "j"

	" Move cursor to previous location
	call cursor(cursor_location)

	" Enable syntax highlighting
	exec "source " . s:plugin_path . "/syntax/filetree.vim"

	setlocal nomodifiable
endfunction

" }}}

" FUNCTION: filetree#Get(expr) {{{1
function! filetree#Get(expr)
	exec "return " . a:expr
endfunction

" }}}

" ==============================================================================
" Keyboard mapping functions
" ==============================================================================
" FUNCTION: filetree#Reload() {{{1
function! filetree#Reload()
	let s:tree = s:GenerateTree(s:pwd, 0)
	call s:Print()
endfunction

" }}}
" FUNCTION: filetree#Scroll(direction) {{{1
function! filetree#Scroll(direction)
	if a:direction == "up"
		norm! k
	else
		norm! j
	endif
endfunction
" }}}
" FUNCTION: filetree#Edit() {{{1
function! filetree#Edit()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = s:tree[file_index].path
	endif

	if s:GetProperty(path, "d")
		call s:ChangeDirectory(path)
		call s:Print()
	else
		wincmd p
		exec "edit " . resolve(path)
	endif
endfunction

" }}}
" FUNCTION: filetree#Open() {{{1
function! filetree#Open()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = s:tree[file_index].path
	endif

	if s:GetProperty(path, "d")
		if s:tree[file_index].open
			call s:CloseDirectory(file_index)
		else
			call s:OpenDirectory(file_index)
		endif
		call s:Print()
	endif
endfunction

" }}}
" FUNCTION: filetree#OpenAll() {{{1
function! filetree#OpenAll()
	let level = 0
	while 1
		let dir_list = []
		let any_closed = 0

		for i in range(len(s:tree))
			let q = s:tree[i]

			if q.level == level && q.end == "/" && (q.name[0:0] != "." || s:show_hidden)
				call add(dir_list, i)
				if q.open == 0
					let any_closed = 1
				endif
			endif
		endfor

		if len(dir_list) == 0
			return
		elseif any_closed == 0
			let level += 1
			continue
		else
			for i in range(len(dir_list))
				let reverse = dir_list[len(dir_list) - 1 - i]
				call s:OpenDirectory(reverse)
			endfor

			call s:Print()
			return
		endif
	endwhile
endfunction

" }}}
" FUNCTION: filetree#CloseAll() {{{1
function! filetree#CloseAll()
	let s:opendirs = []
	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#DirShift(direction) {{{1
function! filetree#DirShift(direction)
	let file_index = s:CursorIndex()
	if file_index == -1
		let path = s:pwd
	else
		let path = s:tree[file_index].path
	endif

	if a:direction == "up"
		if index(s:opendirs, s:pwd) == -1
			call add(s:opendirs, s:pwd)
		endif

		if len(split(s:pwd, "/")) <= 1
			let new_dir = "/"
		else
			let new_dir_list = split(s:pwd, "/")[0:-2]
			let new_dir = "/" . join(new_dir_list, "/")
		endif

	elseif a:direction == "down"
		if path == s:pwd
			return
		endif

		let new_dir_level = len(split(s:pwd, "/"))
		let new_dir_list = split(path, "/")[0:new_dir_level]
		let new_dir = "/" . join(new_dir_list, "/")
	endif

	call s:ChangeDirectory(new_dir)
	call s:Print()
	call cursor(s:GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filetree#DirMove(direction) {{{1
function! filetree#DirMove(direction)
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = s:tree[file_index].path
	endif

	" If moving up a level (h)
	if a:direction == "up"
		let new_path = "/" . join(split(path, "/")[0:-2], "/")

		if new_path == s:pwd
			return
			" Remove return statement to go up a directory when in top level
			let new_pwd = "/" . join(split(new_path, "/")[0:-2], "/")
			call s:ChangeDirectory(new_pwd)
		endif

		" Close the directory
		call s:CloseDirectory(s:GetIndex(new_path))

		call s:Print()
		call cursor(s:GetLine(new_path), 1)

		" If moving down a level (l)
	elseif a:direction == "down"
		if s:GetProperty(path, "d")
			" If the directory is closed, open it
			if index(s:opendirs, path) == -1
				call s:OpenDirectory(s:GetIndex(path))
				call s:Print()
			endif

			" If there are any files, go to the first one
			if file_index != len(s:tree) - 1 && s:tree[file_index + 1].level > s:tree[file_index].level
				norm j
			endif
		endif
	endif
endfunction

" }}}
" FUNCTION: filetree#ShowInfo() {{{1
function! filetree#ShowInfo()
	let path = s:tree[s:CursorIndex()].path
	let real_path = resolve(path)

	" Create a string with the path at the top to display
	let info = path . "\n"

	" Detect if it is a link and show the redirect path
	let redirect = system("readlink '" . path . "' 2> /dev/null")
	if redirect != ""
		let info .= "Redirects to: " . redirect
	endif

	" Get the file type, and if it is a normal file get its size
	let type = system("stat -c %F '" . path . "' 2> /dev/null")
	let info .= "File Type: " . substitute(type, "^.", "\\u&", "g")

	" Get the file size, or the size of the contents of a directory
	let size = split(system("du -sh '" . real_path . "' 2> /dev/null"), "	")[0]
	if type[0:2] == "dir" || type[0:2] == "sym"
		let info .= "Size of Contents: " . size . "\n"
	else
		let info .= "File Size: " . size . "\n"
	endif

	" Get other miscellaneous info
	let info .= "Created: " . system("stat -c %w '" . path . "' 2> /dev/null")
	let info .= "Owner: " . system("stat -c %U '" . path . "' 2> /dev/null")
	let info .= "Permissions: " . system("stat -c %A '" . path . "' 2> /dev/null")
	echo info
endfunction

" }}}
" FUNCTION: filetree#ShowHidden(value) {{{1
function! filetree#ShowHidden(value)
	let path = s:tree[s:CursorIndex()].path
	if a:value == 0
		let s:show_hidden = 0
	elseif a:value == 1
		let s:show_hidden = 1
	else
		let s:show_hidden = !s:show_hidden
	endif

	call s:Print()
	call cursor(s:GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filetree#NavigateTo(dir) {{{1
function! filetree#NavigateTo(dir)
	let s:opendirs = []
	let old_path = s:pwd

	if a:dir == ".."
		if s:pwd == "/"
			return
		endif

		let path = "/" . join(split(s:pwd, "/")[0:-2], "/")
	else
		let path = expand(a:dir)
	endif

	call s:ChangeDirectory(path)
	call s:Print()

	" Detect if the old path is in the current path, and if so got to its folder
	let old_split = split(old_path, "/")
	let new_split = split(path, "/")
	let level = len(new_split) - 1

	let folder = ""
	if level == -1
		let folder = "/" . old_split[0]
	elseif len(old_split) - 1 > level && old_split[0:level] == new_split
		let folder = "/" . join(old_split[0:level + 1], "/")
	endif

	if folder == ""
		call cursor(s:first_line, 1)
	else
		call cursor(s:GetLine(folder), 1)
	endif
endfunction

" }}}

" FUNCTION: filetree#AddFile(type) {{{1
function! filetree#AddFile(type)
	if a:type == "f" || a:type == "file"
		let type = 1
	elseif a:type == "d" || a:type == "directory" || a:type == "dir"
		let type = 2
	else
		let type = confirm("What would you like to create? ", "&File\n&Directory")
	endif

	let name = input("New file name: ")
	let dir = s:GetCursorDirectory()
	let cmd = (type == 1) ? "touch" : "mkdir"

	exec "silent " . substitute("!" . cmd . " '" . dir . "/" . name . "'", "\n", "", "g")

	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#SetExecutable(value) {{{1
function! filetree#SetExecutable(value) 
	let file_index = s:CursorIndex()
	if file_index == -1 || s:tree[file_index].end == "/"
		return
	else
		let path = s:tree[file_index].path
	endif

	if a:value == 0
		silent exec "!chmod -x '" . path . "'"
		let s:tree[file_index].end = ""
	elseif a:value == 1
		silent exec "!chmod +x '" . path . "'"
		let s:tree[file_index].end = "*"
	else
		if s:tree[file_index].end == "*"
			silent exec "!chmod -x '" . path . "'"
			let s:tree[file_index].end = ""
		else
			silent exec "!chmod +x '" . path . "'"
			let s:tree[file_index].end = "*"
		endif
	endif

	call s:Print()
endfunction

" }}}
" FUNCTION: filetree#DeleteFile() {{{1
function! filetree#DeleteFile()
	let file_index = s:CursorIndex()
	if file_index == -1
		let path = s:pwd
		let s:pwd = system("dirname '" . system("dirname '" . s:pwd . "'") . "'")
	else
		let path = s:tree[file_index].path
	endif
	let name = split(path, "/")[-1]

	if s:GetProperty(path, "L")
		let confirmed = input("Deleting link '" . name . "': y/N")
	elseif s:GetProperty(path, "d")
		let file_count = substitute(system("find '" . name . "' -type f | wc -l"), "", "", "g")

		if file_count == 0
			let confirmed = input("Deleting empty directory '" . name . "': y/N")
		elseif file_count == 1
			let confirmed = input("Deleting directory '" . name . "' and 1 file: y/N")
		else
			let confirmed = input("Deleting directory '" . name . "' and " . file_count . " files: y/N")
		endif

	else
		let confirmed = input("Deleting file '" . name . "': y/N")
	endif

	if confirmed != "y" && confirmed != "Y"
		return
	endif

	silent exec "!rm -rf '" . path . "'"

	call remove(s:tree, s:GetIndex(path))
	call s:Print()
endfunction

" }}}
" FUNCTION: filetree#RenameFile() {{{1
function! filetree#RenameFile()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = s:tree[file_index].path
	endif

	let dir_path = join(split(path, "/")[0:-2], "/")
	if dir_path == ""
		let dir_path = "/"
	else
		let dir_path = "/" . dir_path . "/"
	endif

	let new_name = input("New name: ")

	if stridx(new_name, "/") != -1
		echo "New name cannot contain a slash"
	endif

	silent exec "!mv '" . path . "' '" . dir_path . new_name . "'"

	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#MoveFile(action) {{{1
function! filetree#MoveFile(action)
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = s:tree[file_index].path
	endif

	if a:action == "copy"
		let statement = "Navigate to the folder where you want to create the copy"
		let prompt = "Path of copy: "
		let command = "cp -r"
	elseif a:action == "link"
		let statement = "Navigate to the folder where you want to create the link"
		let prompt = "Path of link: "
		let command = "ln -s"
	else
		let statement = "Navigate to the folder where you want to move the file"
		let prompt = "New path: "
		let command = "mv"
	endif

	echo statement . ", and press x to select it"
	exec "noremap <buffer> <silent> <nowait> x :call filetree#ConfirmMove('" . path . "', '" . command . "', '" . prompt . "')<CR>"
endfunction

function! filetree#ConfirmMove(path, command, prompt)
	let name = split(a:path, "/")[-1]
	let new_path = input(a:prompt, s:GetCursorDirectory() . "/" . name)
	exec "!" . a:command . " '" . a:path . "' '" . new_path . "'"

	silent! unmap x
	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#GitCmd(cmd) {{{1
function! filetree#GitCmd(cmd)
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = s:tree[file_index].path
	endif

	" Move to the parent directory of the file
	let real_dir = getcwd()
	let dir = s:GetCursorDirectory()
	exec "cd " . dir

	if a:cmd == "add"
		silent exec "!git add '" . path . "'"

	elseif a:cmd == "commit"
		let commit_message = input("Commit Message: ")
		exec "!git commit -m '" . commit_message . "'"

	elseif a:cmd == "ammend"
		let last_commit = split(system("git log --oneline"), "\n")[0]
		let last_message = last_commit[8:-1]
		let commit_message = input("Ammended Commit Message: ", last_message)
		silent exec "!git commit --amend -m '" . commit_message . "'"

	elseif a:cmd == "log"
		let output = system("git log --oneline")
		echo output
	endif

	" Go back to the origional directory
	exec "cd " . real_dir

	call filetree#Reload()
endfunction

" }}}

" ==============================================================================
" Reference functions
" ==============================================================================
" FUNCTION: s:GenerateTree(dir, level) {{{1
function! s:GenerateTree(dir, level)
	let new_tree = [] " Local variable storing the entire tree for the current level of the function

	" Get the list of files in the current directory, and with link endings
	let cmd = "ls -AFv --group-directories-first"
	let files = split(system(cmd . " -L '" . a:dir . "' 2> /dev/null"), "\n")
	let link_ending = split(system(cmd . " -H '" . a:dir . "' 2> /dev/null"), "\n")

	" Detect if the current directory is a git directory
	let real_pwd = getcwd()
	exec "cd " . a:dir

	let git_dir = split(system("git rev-parse --show-toplevel"), "\n")[0]
	if git_dir[0] != "/"
		let git_dir = ""
	endif

	" Get a prefix to add to the beginning of all of the files to represent their full path
	let dir_prefix = (a:dir == "/") ? ("/") : (a:dir . "/")

	" Get a list of open directories that are in the current directory
	let here_opendirs = []
	let dir_split = split(a:dir, "/")
	let dir_level = len(dir_split)
	for q in s:opendirs
		" If there is an open directory in the current directory
		if split(q, "/")[0:-2] == dir_split
			call add(here_opendirs, q)
		endif
	endfor

	" Loop through each file in the specified directory
	for i in range(len(files))
		let file = files[i]
		let indicator = file[-1:-1]

		" Create a new list for the current tree item
		let new_item = {}
		let new_item.level = a:level
		let new_item.pwd = getcwd()

		" Get the name of the file
		if indicator == "*" || indicator == "/"
			let new_item.name = file[0:-2]
			let new_item.end = indicator
		else
			let new_item.name = file
			let new_item.end = ""
		endif
		let new_item.path = dir_prefix . new_item.name

		" Detect if file is a link
		let new_item.link = ""
		if link_ending[i][-1:-1] == "@"
			let new_item.link = "@ " . s:icons.f_redirect . " " . s:GetShortPath(resolve(new_item.path))
		endif

		" Detect if the file is an open directory
		let is_open_dir = 0
		if indicator == "/"
			if index(here_opendirs, new_item.path) != -1
				let is_open_dir = 1
			endif
		endif

		" Generate icons for each file
		if indicator != "/" " If the file is a regular file
			" Figure out the filetype icon
			if new_item.link == ""
				let file_icon = s:GetFiletypeIcon(new_item.name)
			else
				let file_icon = s:icons.f_link
			endif

			" Figure out the file's git status
			let git_icon = " "
			if git_dir != ""
				let git_status = system("git status -s '" . new_item.path . "'")
				if git_status == ""
					let git_icon = s:icons.g_committed
				elseif git_status[1:1] == " "
					let git_icon = s:icons.g_added
				else
					let git_icon = s:icons.g_modified
				endif
			endif

			" Set the starting string
			let new_item.start = git_icon . " " . file_icon . " "

		else " If the file is a directory
			if new_item.link == ""
				let dir_icon = s:icons.f_dir
			else
				let dir_icon = s:icons.f_dirlink
			endif

			if is_open_dir
				let new_item.start = s:icons.f_open . " " . dir_icon . " "
				let new_item.open = 1
			else
				let new_item.start = s:icons.f_closed . " " . dir_icon . " "
				let new_item.open = 0
			endif
		endif

		" Add the file to the new tree
		call add(new_tree, new_item)

		" Check if it is an open directory, and if so generate its contents
		if is_open_dir
			let subtree = s:GenerateTree(new_item.path, a:level + 1)
			let new_tree = new_tree + subtree
		endif

	endfor

	exec "cd " . real_pwd

	return new_tree
endfunction

" }}}
" FUNCTION: s:GetFiletypeIcon(file) {{{1
function! s:GetFiletypeIcon(file)
	let file_split = split(a:file, "\\.")
	if len(file_split) <= 1 || g:filetree.icon_type == "text"
		return s:icons.f_file
	endif

	let extension = file_split[-1]

	if has_key(s:icons, "e_" . extension)
		return s:icons["e_" . extension]
	else
		return s:icons.f_file
	endif
endfunction
" }}}
" FUNCTION: s:CursorIndex() {{{1
function! s:CursorIndex()
	let line = line(".") - s:first_line
	if line(".") < 0
		return -1
	endif

	if s:show_hidden == 1
		return line
	endif

	let count = 0
	let index = 0
	while count <= line
		if !s:IsHidden(s:tree[index].path)
			let count += 1
		endif
		let index += 1
	endwhile

	return index - 1
endfunction

" }}}
" FUNCTION: s:GetCursorDirectory() {{{1
function! s:GetCursorDirectory()
	let file_index = s:CursorIndex()
	if file_index == -1
		return s:pwd
	endif

	let path = s:tree[file_index].path
	if s:GetProperty(path, "d") == 1
		return path
	else
		return substitute(system("dirname '" . path . "'"), "\n", "", "g")
	endif
endfunction

" }}}
" FUNCTION: s:GetIndex(path) {{{1
function! s:GetIndex(path)
	let index = 0
	for q in s:tree
		if q.path == a:path
			return index
		endif

		let index += 1
	endfor

	return s:first_line
endfunction

" }}}
" FUNCTION: s:GetLine(path) {{{1
function! s:GetLine(path)
	let index = 0
	for q in s:tree
		if q.path == a:path
			return index + s:first_line
		endif

		if s:show_hidden || !s:IsHidden(q.path)
			let index += 1
		endif
	endfor

	return s:first_line
endfunction

" }}}
" FUNCTION: s:IsHidden(path) {{{1
function! s:IsHidden(path)
	let path_split = split(a:path, "/")
	let split_len = len(path_split) - len(split(s:pwd, "/"))
	let g:sl = split_len
	let g:sp = path_split[-split_len:-1]
	for q in path_split[-split_len:-1]
		if q[0:0] == "."
			return 1
		endif
	endfor

	return 0
endfunction

" }}}
" FUNCTION: s:GetProperty(path, property) {{{1
function! s:GetProperty(path, property)
	return system("[[ -" . a:property . " '" . a:path . "' ]] && echo 1")
endfunction

" }}}
" FUNCTION: s:GetShortPath(path) {{{1
function! s:GetShortPath(path)
	" Replace the beginning with ~ if it is in the home directory
	if stridx(a:path, $HOME) == 0
		let long_path = substitute(a:path, $HOME, "~", "")
	else
		let long_path = a:path
	endif

	let split = split(long_path, "/")

	" Return the origional path if it is in the root directory
	if len(split) <= 1
		return a:path
	endif

	" Convert the split into a short path
	let new_path = ""
	for i in range(len(split) - 1)
		let new_path .= split[i][0:0] . "/"
	endfor
	let new_path .= split[-1]

	if new_path[0:0] != "~"
		let new_path = "/" . new_path
	endif

	return new_path
endfunction

" }}}
" FUNCTION: s:ChangeDirectory(dir) {{{1
function! s:ChangeDirectory(dir)
	if s:GetProperty(a:dir, "f")
		return "Not a directory"
	endif

	exec "cd " . a:dir
	let s:pwd = a:dir
	let s:tree = s:GenerateTree(a:dir, 0)
endfunction

" }}}
" FUNCTION: s:OpenDirectory(index) {{{1
function! s:OpenDirectory(index)
	let path = s:tree[a:index].path

	" Cancel the function if it isn't a directory, or if it's already open
	let opendir_index = index(s:opendirs, path)
	if s:GetProperty(path, "f") || opendir_index != -1
		return
	endif

	" Mark the file as open and add it to the list of open directories
	let s:tree[a:index].open = 1
	call add(s:opendirs, path)

	" Change the icon to show that the directory is open
	let s:tree[a:index].start = substitute(s:tree[a:index].start, s:icons.f_closed, s:icons.f_open, "")

	" Add the contents of the directory to the tree
	let subtree = s:GenerateTree(path, s:tree[a:index].level + 1)
	let tree_len = len(s:tree)
	if a:index < tree_len - 1
		let s:tree = s:tree[0:(a:index)] + subtree + s:tree[(a:index + 1):-1]
	else
		let s:tree = s:tree + subtree
	endif
endfunction

" }}}
" FUNCTION: s:CloseDirectory(index) {{{1
function! s:CloseDirectory(index)
	let path = s:tree[a:index].path

	" Cancel the function if it isn't a directory, or if it's already open
	let opendir_index = index(s:opendirs, path)
	if s:GetProperty(path, "f") || opendir_index == -1
		return
	endif

	" Mark the file as closed, and remove it from the list of open directories
	let s:tree[a:index].open = 0
	call remove(s:opendirs, opendir_index)

	" Change the icon to show that the directory is closed
	let s:tree[a:index].start = substitute(s:tree[a:index].start, s:icons.f_open, s:icons.f_closed, "")

	" Remove the contents of the directory from the tree
	let level = s:tree[a:index].level
	let end_index = a:index + 1
	if s:tree[end_index].level <= level
		return
	endif

	while end_index + 1 < len(s:tree) && s:tree[end_index + 1].level > level
		let end_index += 1
	endwhile

	if end_index == len(s:tree) - 1
		let s:tree = s:tree[0:(a:index)]
	else
		let s:tree = s:tree[0:(a:index)] + s:tree[end_index + 1:-1]
	endif
endfunction

" }}}
