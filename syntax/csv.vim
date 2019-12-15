" Vim syntax file
" Language:     Comma-separated value (csv)
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
syn match   csvDelim         +,+

" Field values
syn match   csvValue         +[^,]+
syn match   csvInvalid       +"+
syn match   csvQuoted        +"\([^"]\|"[^,]\@=\)*"+ contains=csvQuotedInside
syn match   csvQuotedInside  +"\zs\([^"]\|"[^,]\@=\)*\ze"+ transparent contained contains=csvVague

" Characters inside field
syn match   csvVague         +,+ contained
syn match   csvVague         +"+ contained


"=============================================================================
" Link definitions to syntax types

hi def link csvDelim      Operator

hi def link csvValue      Normal
hi def link csvQuoted     String

hi def link csvVague      SpecialChar
hi def link csvInvalid    Error

let b:current_syntax = "csv"

