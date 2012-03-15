" Vim syntax file
" Language:	VCL
" Maintainer:	Josh Bronson <jabronson@gmail.com>
" Last Change:	2009 Feb 20

" Based on
" http://varnish.projects.linpro.no/browser/trunk/varnish-tools/emacs/vcl-mode.el

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif


syn keyword	vclLogic	else elsif elseif if remove set unset
syn keyword	vclType		purge_url regsub
syn keyword	vclFunction	acl backend sub vcl_deliver vcl_discard vcl_error vcl_fetch vcl_hash vcl_hit vcl_miss vcl_pipe vcl_recv vcl_timeout
syn keyword	vclAction	deliver discard error fetch hash keep lookup pass pipe

set iskeyword+=.
syn keyword	vclVariable	backend.host backend.port
syn keyword	vclVariable	bereq.proto bereq.request bereq.url
syn keyword	vclVariable	client.ip
syn keyword	vclVariable	now
syn keyword	vclVariable	obj.cacheable obj.lastuse obj.proto obj.response obj.status obj.ttl obj.valid
syn keyword	vclVariable	req.backend req.grace req.hash req.proto req.request req.url
syn keyword	vclVariable	resp.proto resp.response resp.status
syn keyword	vclVariable	server.ip
syn match	vclVariable	"\(req\|resp\|obj\)\.http\.[A-Za-z-]\+"

syn keyword	vclTodo		contained TODO FIXME XXX

syn match	vclComment	"#.*" contains=vclTodo
syn match	vclComment	"\/\/.*" contains=vclTodo
syn region	vclComment	start="/\*" end="\*/" keepend contains=vclTodo,vclVariable

syn region	vclBlock	start="{" end="}" transparent fold

syn region	vclString	start="'" end="'"
syn region	vclString	start=+"+  end=+"+

syn region	vclSynthetic	start="synthetic {\"" end="\"};" keepend

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi def link vclLogic		Conditional
hi def link vclType		Type
hi def link vclFunction		Operator
hi def link vclAction		Statement
hi def link vclVariable		Label
hi def link vclTodo		Todo
hi def link vclComment          Comment
hi def link vclString		String
hi def link vclSythetic		String


let b:current_syntax = "vcl"

" vim: ts=8

