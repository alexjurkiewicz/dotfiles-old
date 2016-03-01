runtime! debian.vim

" See http://vimdoc.sourceforge.net/htmldoc/options.html
set incsearch nocompatible showmatch ignorecase smartcase scrolloff=5 noai vb t_vb= noerrorbells wildmenu t_Co=256 modelines=3 smarttab
" :set noet ts=8 to temporarily override
set et ts=4 softtabstop=4 shiftwidth=4
" allow backspacing over everything
set backspace=indent,eol,start

" Filetype-specific configuration
" http://vimdoc.sourceforge.net/htmldoc/syntax.html#syntax
syntax on
syntax sync minlines=200
filetype plugin indent on
au BufRead,BufNewFile /etc/nginx/* set ft=nginx
au BufRead,BufNewFile nginx.conf* set ft=nginx
au BufRead,BufNewFile */httpd/*.conf set ft=apache
au BufRead,BufNewFile */apache/*.conf set ft=apache
au BufRead,BufNewFile *.jinja set ft=htmljinja
au BufRead,BufNewFile *.textile set ft=textile
au BufRead,BufNewFile *.pp set ft=puppet
au BufRead,BufNewFile *.mako set ft=html
au BufRead,BufNewFile *.des set ft=levdes
au FileType python setlocal et ts=4 softtabstop=4 shiftwidth=4
" Assume /bin/sh is posix-compatible (not bourne-compatible)
let g:is_posix=1

" Reopen files where we left off
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

" Remember for 100 files: 1000 lines per register, but not for files in /mnt or /media or /tmp. Save to ~/.viminfo
set viminfo='100,s1000,r/mnt,r/media,r/tmp,r~.git/COMMIT_EDITMSG,n~/.viminfo

" Theme settings
set bg=dark
colorscheme inkpot
