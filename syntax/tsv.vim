" Vim syntax file
" Language:     Tab-separated value (tsv)
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
syn match   tsvDelim         +\t+

" Field values
syn match   tsvValue         +[^\t]+
syn match   tsvInvalid       +"+
syn match   tsvQuoted        +"\([^"]\|"[^\t]\@=\)*"+ contains=tsvQuotedInside
syn match   tsvQuotedInside  +"\zs\([^"]\|"[^\t]\@=\)*\ze"+ transparent contained contains=tsvVague

" Characters inside field
syn match   tsvVague         +\t+ contained
syn match   tsvVague         +"+ contained


"=============================================================================
" Link definitions to syntax types

hi def link tsvDelim      Operator

hi def link tsvValue      Normal
hi def link tsvQuoted     String

hi def link tsvVague      SpecialChar
hi def link tsvInvalid    Error

let b:current_syntax = "tsv"

