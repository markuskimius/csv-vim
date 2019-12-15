" Vim syntax file
" Language:     Pipe-separated value (psv)
" Maintainer:   Mark Kim
" License:      Apache License 2.0
" URL:          https://github.com/markuskimius/csv-vim
" Last change:  2019 Dec 15

" Do not load syntax file twice
if exists("b:current_syntax")
  finish
endif


"=============================================================================
" Comma-seprated value file syntax

" Operators
syn match   psvDelim         +|+

" Field values
syn match   psvValue         +[^|]+
syn match   psvInvalid       +"+
syn match   psvQuoted        +"\([^"]\|"[^|]\@=\)*"+ contains=psvQuotedInside
syn match   psvQuotedInside  +"\zs\([^"]\|"[^|]\@=\)*\ze"+ transparent contained contains=psvVague

" Characters inside field
syn match   psvVague         +|+ contained
syn match   psvVague         +"+ contained


"=============================================================================
" Link definitions to syntax types

hi def link psvDelim      Operator

hi def link psvValue      Normal
hi def link psvQuoted     String

hi def link psvVague      SpecialChar
hi def link psvInvalid    Error

let b:current_syntax = "psv"

