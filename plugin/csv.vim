" Macros for editing csv files
" Maintainer:   Mark Kim
" License:      Apache License 2.0
" URL:          https://github.com/markuskimius/csv-vim
" Last change:  2019 Dec 15
"
" References:
"
"   http://vim.wikia.com/wiki/Navigate_large_CSV_files_more_easily
"   http://www.vim.org/scripts/script.php?script_id=309


" ============================================================================
" INITIALIZATION FUNCTIONS

" Function to call when loading
function! CsvOnLoad()
    let b:csvHeader = 1        " Header is on line 1
    let b:csvColumn = 0        " Select column 1
    let b:csvColSpan = 1       " ... and it spans 1 column
    let b:csvStatLine = 0      " Status line shoul show: 0 = Header, [1-9]+ = Column
    let b:csvTimerInterval = 1 " Copy/Cut/Del statusline update interval for timer
    let b:csvJumpDir = 'f'     " Default jump direction ('f' = fwd, 'b' = bwd)

    set nowrap
    call CsvAutoDetectDelim()
endfunction


" Function to call when unloading
function! CsvOnUnload()
    call CsvHiliteOff()
endfunction


" Auto detect the CSV delimiter and set it.
function! CsvAutoDetectDelim()
    let line = getline(1)
    let commas = strlen( substitute(line, '[^,]*', '', 'g') )
    let pipes = strlen( substitute(line, '[^|]*', '', 'g') )
    let tabs = strlen( substitute(line, '[^\t]*', '', 'g') )

    if commas > pipes
        let b:csvDelim = ','
    elseif pipes > 0
        let b:csvDelim = '|'
    elseif tabs > 0
        let b:csvDelim = "\t"
    else
        let b:csvDelim = ','
        set filetype=csv
    endif

    "call RefreshCsvInfo()
endfunction


" ============================================================================
" CONFIGURATION FUNCTIONS

" Set the line number where the field headers are located
" line 1 is the first line.  If the line number is empty,
" the current line is used.
"
" Examples:
"   :call CsvSetHeader()         " Use the current line as the header
"   :call CsvSetHeader(1)        " Use the first line as the header
"
function! CsvSetHeader(...)
    let lineno = line('.')
    if a:0 > 0
        let lineno = a:1
    endif

    let b:csvHeader = lineno
    echo 'Line '.lineno.' set as the CSV header'
endfunction


" Return true if a delimiter is a valid delimiter, false otherwise.  A
" character is a valid delimiter if:
"
" - The character does not have a special meaning inside nor outside
"   a regex character class.
"
" - It is a single character.
"
" These are restrictions imposed by the regexes used throughout the
" script.  It is possible to expand the valid character set list if
" the regexes are modified.
"
function! CsvIsValidDelim(delim)
    if a:delim =~# '^[0-9A-Za-z_,|\t~`!@#%&()_+={}:;<>?,]$'
        return 1
    else
        return 0
    endif
endfunction


" Set the field delimiter.  Make sure the delimiter does not have any
" special meaning in regex because otherwise it can break the regexes
" that use its value.
"
function! CsvSetDelim(delim)
    let b:csvDelim = a:delim

    if CsvIsValidDelim(a:delim)
        call CsvHilite()
        echo 'Column delimiter set to ' . a:delim
    else
        echo 'Invalid delimiter: ' . a:delim
    endif
endfunction


" Set the CSV span.  1 means select 1 column.
function! CsvSetSpan(span)
    if a:span <= 0
        echo 'Invalid span parameter'
        sleep 1
        redraw
    else
        let b:csvColSpan = a:span
    endif

    call CsvHilite()
    echo 'Column span set to ' . b:csvColSpan
endfunction


" Set the CSV span to 1 and select the current column.
function! CsvSetSpanToBegin()
    let b:csvColumn = CsvGetColNum()
    let b:csvColSpan = 1

    call CsvHilite()
    echo 'Column span set to ' . b:csvColSpan
endfunction


" Set the CSV span from the current column to the last column and select
" current column.
function! CsvSetSpanToEnd()
    let l = getline('.')
    let col1 = CsvLineGetColNum(l, col('.')-1)
    let col2a = CsvLineGetColCount(l)

    let b:csvColumn = col1
    let b:csvColSpan = col2a - col1

    call CsvHilite()
    echo 'Column span set to ' . b:csvColSpan
endfunction


" Increment the CSV span.
function! CsvIncSpan(amt)
    let newspan = b:csvColSpan + a:amt

    if newspan <= 0
        call CsvSetSpan(1)
    else
        call CsvSetSpan(newspan)
    endif
endfunction


" Decrement the CSV span.
function! CsvDecSpan(amt)
    let newspan = b:csvColSpan - a:amt

    if newspan < 1
        echo 'Column span already at minimum'
    else
        call CsvSetSpan(newspan)
    endif
endfunction


" Set what should go on the status line.  If arg is 0, the header is displayed.
" If it is any other numeral, current line's column is displayed where 1 is the
" first column.
"
function! CsvSetStatLine(arg)
    let b:csvStatLine = a:arg
    call CsvRefresh()
endfunction


" ============================================================================
" DISPLAY FUNCTIONS

" Highlight the selected columns.
"
" Adapted from Vim Tip #667:
" http://vim.wikia.com/wiki/Navigate_large_CSV_files_more_easily
"
function! CsvHilite()
    let c = b:csvColumn
    let s = b:csvColSpan - 1
    let d = b:csvDelim

    if c == 0
        if s == 0
            execute 'match Visual /^\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)/'
        elseif s > 0
            execute 'match Visual /^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{,'.s.'}\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)/'
        endif
    elseif c > 0
        if s == 0
            execute 'match Visual /^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{'.c.'}\zs\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)/'
        elseif s > 0
            execute 'match Visual /^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{'.c.'}\zs\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{,'.s.'}\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)/'
        endif
    endif
endfunction


" Hide the column highlighting
function! CsvHiliteOff()
    execute 'match'
endfunction


" ============================================================================
" NAVIGATION PRIMITIVES

" Move the cursor to the specified column.
" col 0 is the first column.
"
function! CsvColJump(colnum)
    let l = getline('.')
    let charpos = CsvLineGetCharPos(l, a:colnum)

    call cursor(line('.'), charpos+1)
endfunction


" ============================================================================
" CSV LINE FUNCTIONS

" Given a line of CSV text, return the valid portion of the CSV line without
" the invalid portion.
"
function! CsvLineValidate(csvline)
    let d = b:csvDelim
    let vl = matchstr(a:csvline, '^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)*\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)')

    return vl
endfunction


" Given a line of CSV text, return the invalid portion of the CSV line
" without the valid portion.
"
function! CsvLineInvalidPart(csvline)
    let vl = CsvLineValidate(a:csvline)
    let start = strlen(vl)

    return strpart(a:csvline, start)
endfunction


" Given a line of CSV text, return 1 if the csvline validates, false
" otherwise.
"
function! CsvLineIsOk(csvline)
    let vl = CsvLineValidate(a:csvline)

    if strlen(a:csvline) == strlen(vl)
        return 1
    else
        return 0
    endif
endfunction


" Given a line of CSV text and the column number, return the character
" position of the first character of the specified column.
"
"   @param csvline    CSV line text.
"   @param colnum     Column number on that line.
"
" 0 is the first character position.  0 is the first CSV column.
"
function! CsvLineGetCharPos(csvline, colnum)
    if a:colnum > 0
        let l = a:csvline
        let c = a:colnum
        let d = b:csvDelim

        let sl = substitute(l, '^\(\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{'.c.'}\).*$', '\1', '')
    else
        let sl = ''
    endif
    let charpos = strlen(sl)

    return charpos
endfunction


" Given a line of CSV text and the character position, return the column
" number at the character location.
"
"   @param csvline    CSV line text
"   @param charpos    Character position on that line.
"
" 0 is the first character position.  0 is the first CSV column.
"
function! CsvLineGetColNum(csvline, charpos)
    let l = CsvLineValidate(a:csvline)
    let sl = strpart(l, 0, a:charpos)
    let d = b:csvDelim

    let delims = substitute(sl, '[^"]\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*\("\|$\)', '', 'g')
    let csvcol = strlen(delims)

    return csvcol
endfunction


" Given a CSV line text, return the total number of columns on that line.
"
function! CsvLineGetColCount(csvline)
    let l = CsvLineValidate(a:csvline)
    let d = b:csvDelim

    let delims = substitute(l, '[^"]\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"', '', 'g')
    let csvcol = strlen(delims)

    return csvcol + 1
endfunction


" Given a line of CSV text and the column number, return the field value of
" that column.
"
" 0 is the first CSV column.
"
function! CsvLineGetField(csvline, colnum)
    let c = a:colnum
    let d = b:csvDelim
    let l = a:csvline
    let field = ''

    if c == 0
        let field = matchstr(l, '^\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)')
    elseif c > 0
        let field = matchstr(l, '^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{'.c.'}\zs\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)')
    endif

    return field
endfunction


" Given a line of CSV text, the starting column number, and the column span,
" return the field values of that column to column+span.
"
" 0 is the first CSV column.
"
function! CsvLineGetFields(csvline, col1, span)
    let totcol = CsvLineGetColCount(a:csvline)
    let col2 = a:col1 + a:span
    let s = ''

    let i = a:col1
    while i < col2 && i < totcol
        let s = s . b:csvDelim . CsvLineGetField(a:csvline, i)
        let i = i + 1
    endwhile

    return strpart(s,1)
endfunction


" Given a line of CSV text, a column number, and a new value, change the
" value of the CSV text on the specified column to the new value.
"
" 0 is the first CSV column.
"
function! CsvLineSetField(csvline, colnum, newval)
    let l = a:csvline
    let d = b:csvDelim
    let c = a:colnum
    let n = a:newval

    if c == 0
        let l = substitute(l, '^\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)', n, '')
    elseif c > 0
        let l = substitute(l, '^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\)\{'.c.'}\zs\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)', n, '')
    endif

    return l
endfunction


" Given a line of CSV text, a starting column number, and deliminated field
" values, set the values at the start column number and following to the
" specified values.
"
" 0 is the first CSV column.
"
function! CsvLineSetFields(csvline, col1, values)
    let l = a:csvline
    let maxcol = CsvLineGetColCount(a:values)

    call CsvLineExtendCols(l, a:col1+maxcol)

    let i = 0
    while i < maxcol
        let v = CsvLineGetField(a:values, i)
        let l = CsvLineSetField(l, a:col1+i, v)

        let i = i + 1
    endwhile

    return l
endfunction


" Given a line of CSV text, a column number, and a value, insert the
" specified value to the column, shifting right all existing columns.
"
" 0 is the first CSV column.
"
function! CsvLineInsCol(csvline, colnum, val)
    let l = a:csvline
    let tot = CsvLineGetColCount(l)

    " If the line has no data, we can consider that line to have no column
    if strlen(l)==0
        let tot = 0
    endif

    if a:colnum > tot
        let tot = a:colnum
    endif

    let l = CsvLineExtendCols(l, tot+1)
    let l = CsvLineShiftR(l, a:colnum, tot)
    let l = CsvLineSetField(l, a:colnum, a:val)

    return l
endfunction


" Given a line of CSV text and a column number, delete the specified CSV
" column.
"
" 0 is the first CSV column.
"
function! CsvLineDelCol(csvline, colnum)
    let l = a:csvline
    let d = b:csvDelim
    let c = a:colnum
    let n = ''

    if c == 0
        let l = substitute(l, '^\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)'.d.'\?', n, '')
    elseif c > 0
        let l = substitute(l, '^\(\%(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)\zs'.d.'\)\{'.c.'}\(\%([^"]\|$\)\@=[^'.d.']*\|"\%([^"]\|"[^'.d.']\@=\)*"\)', n, '')
    endif

    return l
endfunction


" Given a line of CSV text, a column number, and the column span, delete the
" CSV columns that fall within the column ranges.
"
" 0 is the first CSV column.
"
function! CsvLineDelCols(csvline, col1, span)
    let l = a:csvline

    let i = 0
    while i < a:span
        let l = CsvLineDelCol(l, a:col1)

        let i = i + 1
    endwhile

    return l
endfunction


" Given a line of CSV text, a column number, the column span, and CSV fields,
" replace the CSV columns that fall within the column ranges with the new
" values.  The data is replaced only if there is data on the starting column.
"
" 0 is the first CSV column.
"
function! CsvLineReplCols(csvline, col1, span, fields)
    let l = a:csvline
    let colcount = CsvLineGetColCount(l)
    let vl = CsvLineValidate(l)
    let il = CsvLineInvalidPart(l)
    let d = b:csvDelim

    if strlen(vl) == 0
        let colcount = 0
    endif

    if a:col1 < colcount
        let vl = CsvLineDelCols(vl, a:col1, a:span)
        let vl = CsvLineInsCol(vl, a:col1, a:fields)

        let il = substitute(il, '^[^'.d.']\@=', d, '')
        let l = vl.il
    endif

    return l
endfunction


" Given a line of CSV text and a column count, extend the column count of
" the line to at least the given column count.
"
function! CsvLineExtendCols(csvline, colcount)
    let now = CsvLineGetColCount(a:csvline)
    let vl = CsvLineValidate(a:csvline)
    let il = CsvLineInvalidPart(a:csvline)
    let d = b:csvDelim

    while now < a:colcount
        let vl = vl . d
        let now = now + 1
    endwhile

    let il = substitute(il, '^[^'.d.']\@=', d, '')
    return vl.il
endfunction


" Given a line of CSV text and two column numbers col1 and col2, shift
" all CSV field values between col1 to col2 to right.
"   col1 will be blank.
"   col1+1 will be replaced by col1.
"   col2 will be replaced by col2-1.
"   col2+1 will not be replaced.
function! CsvLineShiftR(csvline, col1, col2)
    let col1val = CsvLineGetField(a:csvline, a:col1)
    let vl = CsvLineValidate(a:csvline)
    let il = CsvLineInvalidPart(a:csvline)
    let d = b:csvDelim

    if a:col1 < a:col2
        let vl = CsvLineDelCol(vl, a:col2)
        let vl = CsvLineSetField(vl, a:col1, b:csvDelim.col1val)
    endif

    let il = substitute(il, '^[^'.d.']\@=', d, '')
    return vl.il
endfunction


" Return -1 if none of the columns match regex after the column "startcol"
" spanning a:1 columns (default is to the end), or return the column number
" of the first column that matches the regex after the column "startcol"
function! CsvLineColMatch(csvline, regex, startcol, ...)
    let max = CsvLineGetColCount(a:csvline)
    let col = -1

    if a:0 > 0
        let max = a:startcol + a:1
    endif

    let i = a:startcol
    while i < max
        let f = CsvLineGetField(a:csvline, i)

        if match(f, a:regex) >= 0
            let col = i
            break
        endif

        let i = i + 1
    endwhile

    return col
endfunction


" Same as CsvLineColMatch except search fields in the reverse direction.
function! CsvLineColMatchR(csvline, regex, startcol, ...)
    let max = CsvLineGetColCount(a:csvline)
    let col = -1

    if a:0 > 0
        let max = a:startcol + a:1
    endif

    let i = max
    while i > 0
        let i = i - 1
        let f = CsvLineGetField(a:csvline, i)

        if match(f, a:regex) >= 0
            let col = i
            break
        endif
    endwhile

    return col
endfunction


" Return true if the first column of the csvline matches regex, false
" otherwise.
function! CsvLineMatchesRegex1(csvline, regex)
    return CsvLineColMatch(a:csvline, a:regex, 0, 1) >= 0
endfunction


" Run a substitution operation on all the selected columns.
function! CsvLineSubstitute(csvline, regex, repl, flags)
    let l = a:csvline
    let max = CsvLineGetColCount(a:csvline)

    let i = 0
    while i < max
        let f = CsvLineGetField(l, i)
        let f = substitute(f, a:regex, a:repl, a:flags)
        let l = CsvLineSetField(l, i, f)

        let i = i + 1
    endwhile

    return l
endfunction


" ============================================================================
" CSV BUFFER FUNCTIONS

" Count the number of lines in a variable.
function! CsvVarCountLines(buf)
    let buf = substitute(a:buf, "[^\n]*[\n]\\?", '*', 'g')

    return strlen(buf) + 1
endfunction


" Grab line "linenum" from the variable "buf".
" 0 is the first line (I know... I'm being inconsistent.  Shame on me.
" at least I'm documenting it.)
"
function! CsvVarGetLine(buf, linenum)
    let l = a:linenum

    if(l <= 0)
        let line = matchstr(a:buf, "^[^\n]*")
    else
        let line = matchstr(a:buf, "^\\([^\n]*[\n]\\)\\{".l."}\\zs[^\n]\\+")
    endif

    return line
endfunction


"=============================================================================
" CSV FILE FUNCTIONS

" Grab the field value on the current line at the specified column number.
" 0 is the first column.
function! CsvGetField(colnum)
    let l = getline('.')
    let s = CsvLineGetField(l, a:colnum)

    return s
endfunction


" Grab "span" field values on the current line starting at the specified
" column number.
" 0 is the first column.
function! CsvGetFields(col1, span)
    let l = getline('.')
    let s = CsvLineGetFields(l, a:col1, a:span)

    return s
endfunction


" Return the column number of the current cursor position
function! CsvGetColNum()
    let l = getline('.')
    let charpos = col('.')-1

    return CsvLineGetColNum(l, charpos)
endfunction


" Return the number of columns on the current line.
function! CsvGetColCount()
    let l = getline('.')
    let colcount = CsvLineGetColCount(l)

    return colcount
endfunction


"=============================================================================
" TEXT FUNCTIONS

" Return text formatted to specified width, space padded left.
function! CsvTextW(text, width)
    let t = a:text

    let i = strlen(t)
    while i < a:width
        let t = ' ' . t

        let i = i + 1
    endwhile

    return t
endfunction


" Return column number with the unit suffix.
function! CsvTextCol(colcount)
    let s = a:colcount.' column'.(a:colcount==1 ? '' : 's')

    return s
endfunction


" Return line number with the unit suffix.
function! CsvTextLine(linecount)
    let s = a:linecount.' line'.(a:linecount==1 ? '' : 's')

    return s
endfunction


" Return column and line number with the unit suffixes.
function! CsvTextColLine(colcount, linecount)
    let s = ''
    let s = s . a:colcount.' column'.(a:colcount==1 ? '' : 's').' on '
    let s = s . a:linecount.' line'.(a:linecount==1 ? '' : 's')

    return s
endfunction


"=============================================================================
" UTILITY FUNCTIONS

" Max of two integers
function! CsvUtilMaxInt(a, b)
    let max = (a:a >= a:b) ? a:a : a:b

    return max
endfunction


" Min of two integers
function! CsvUtilMinInt(a, b)
    let min = (a:a <= a:b) ? a:a : a:b

    return min
endfunction


" nmap helper function to calculate the Line1 parameter to CsvCopy,
" CsvCut, CsvPaste, etc.
"
function! CsvUtilNmapL1()
    let line1 = line('.')

    if v:count == 0
        let line1 = 1
    endif

    return line1
endfunction


" nmap helper function to calculate the Line2 parameter to CsvCopy,
" CsvCut, CsvPaste, etc.
"
function! CsvUtilNmapL2()
    let line2 = line('.') + v:count - 1

    if v:count == 0
        let line2 = line('$')
    endif

    return line2
endfunction


" Start timer
function! CsvTimerStart()
    let b:csvTimer = localtime()
endfunction


" Update status line if the timer has expired
function! CsvTimerStat(text)
    if localtime() >= b:csvTimer + b:csvTimerInterval
        echo a:text
        redraw

        let b:csvTimer = localtime()
    endif
endfunction


"=============================================================================
" USER FUNCTIONS

function! CsvEchoInfo()
    let l = getline('.')

    let pos = col('.')-1
    let col = CsvLineGetColNum(l, pos)
    let ok = CsvLineIsOk(l) ? '' : '+'

    let c = col + 1
    let t = CsvLineGetColCount(l)
    let sl = b:csvStatLine

    if sl == 0
        let h = getline(b:csvHeader)
        let slt = 'Header: '.CsvLineGetField(h, col)
    else
        let v = CsvLineGetField(l, sl-1)
        if strlen(v) == 0
            let v = '(none)'
        endif
        let slt = 'Col '.sl.': '.v
    endif

    " Format and echo
    let c = CsvTextW(c, 4)
    let t = CsvTextW(t, 4)
    echo 'Col'.c.' of'.t.ok.'   '.slt
endfunction


function! CsvRefresh()
    call CsvHilite()
    call CsvEchoInfo()
endfunction


function! CsvSelectCol(colnum)
    let b:csvColumn = a:colnum

    if b:csvColumn < 0
        let b:csvColumn = 0
    endif

    call CsvRefresh()
endfunction


function! CsvSelectThisCol()
    let b:csvColumn = CsvGetColNum()

    call CsvRefresh()
endfunction


function! CsvLeft(dx)
    let b:csvColumn = CsvGetColNum() - a:dx
    if b:csvColumn < 0
        let b:csvColumn = 0
    endif

    call CsvColJump(b:csvColumn)
    call CsvRefresh()
endfunction


function! CsvRight(dx)
    let totcol = CsvLineGetColCount(getline('.'))
    let b:csvColumn = CsvGetColNum() + a:dx

    if totcol <= b:csvColumn
        let b:csvColumn = totcol - 1
    endif

    call CsvColJump(b:csvColumn)
    call CsvRefresh()
endfunction


function! CsvUp(dy)
    execute 'normal '.a:dy.'k'

    call CsvJumpHome()
endfunction


function! CsvDown(dy)
    execute 'normal '.a:dy.'j'

    call CsvJumpHome()
endfunction


" Search the header that matches <regex> in the direction <dir>, where the
" direction of 'f' is forward and 'b' is backward search.  Jump to the
" current line's column that corresponds to the found header's column.
"
function! CsvColJumpByHeader(regex, dir)
    let h = getline(b:csvHeader)
    let startcol = CsvGetColNum()
    let wrapped = ''

    " Backward search - Start search from last column backward
    if a:dir == 'b'
        let col = CsvLineColMatchR(h, a:regex, 0, startcol)

        " If no match, then wrap around
        if col < 0
            let col = CsvLineColMatchR(h, a:regex, 0)
            let wrapped = 'Search hit FIRST COLUMN, continuing at LAST COLUMN'
        endif

    " Forward search - Start search from next column forward
    else
        let col = CsvLineColMatch(h, a:regex, startcol+1)

        " If no match, then wrap around
        if col < 0
            let col = CsvLineColMatch(h, a:regex, 0)
            let wrapped = 'Search hit LAST COLUMN, continuing at FIRST COLUMN'
        endif
    endif

    " If no match, display error
    if col < 0
        echo 'Header pattern not found: '.a:regex
    " If match, jump there
    else
        call CsvColJump(col)

        " If there was a search wrap, notify the user
        if strlen(wrapped) > 0
            echo wrapped

            let b:csvColumn = col
            call CsvHilite()
        " If there was no search wrap, just select the found column
        else
            call CsvSelectCol(col)
        endif
    endif
endfunction


" Do a column jump with either a numeric value (which jumps the cursor to
" the specified column) or with a regex value (which jumps to the column on
" the current line corresponding to the column of the header that matches the
" regex) in the direction specified ('f' is forward, 'n' is backward.)
"
function! CsvJump(arg, dir)
    let arg = a:arg
    let b:csvJump = arg

    " If argument is numeric, do column jump
    if arg =~# '^[0-9]\+$'
        " If backward search, count column backwards
        if a:dir == 'b'
            let l = getline(b:csvHeader)
            let col = CsvLineGetColCount(l) - arg
        else
            let col = arg - 1
        endif

        if col < 0
            echo 'Invalid column: '.arg
        else
            call CsvColJump(col)
            call CsvSelectCol(col)
        endif

    " If non-numeric, do regex jump by header
    else
        call CsvColJumpByHeader(arg, a:dir)
    endif
endfunction


" Repeat CsvJump if blank string arg is supplied, otherwise search by the
" supplied argument, in the specified direction.  Direction 'f' is forward,
" 'b' backward.  If CsvJump cannot be repeated because CsvJump was not
" previously called, display an error message.
"
function! CsvJumpSmart(dir, jumpcount, arg)
    let jc = a:jumpcount

    " If no argument supplied and no previous CsvJump call, it's an error
    if a:arg ==# '' && !exists('b:csvJump')
        echo 'No previous call to CsvJump'

    " If no argument, use previous argument to jump; otherwise use the argument
    else
        if a:arg == ''
            let arg = b:csvJump
        else
            let arg = a:arg
        endif

        " If numeric column supplied, jump only once since repeat search will
        " end up in the same column
        if arg =~# '^[0-9]\+$'
            let jc = 1
        endif

        " Jump as many times as is specified
        let i = 0
        while i < jc
            redraw
            call CsvJump(arg, a:dir)

            let i = i + 1
        endwhile
    endif

    " Remember the jump direction
    let b:csvJumpDir = a:dir
endfunction


" CsvJumpSmart with the reverse direction sense
function! CsvJumpSmartR(dir, jumpcount, arg)
    let dir = 'b'
    if a:dir == 'b'
        let dir = 'f'
    endif

    " Jump
    call CsvJumpSmart(dir, a:jumpcount, a:arg)

    " Remember the jump direction
    let b:csvJumpDir = a:dir
endfunction


" Jumpe to the selected column and highlight
function! CsvJumpHome()
    call CsvColJump(b:csvColumn)
    call CsvRefresh()
endfunction


" Echo all selected columns' values between line1 and line2, inclusive.
function! CsvEcho(line1, line2)
    let i = a:line1
    while i <= a:line2
        let l = getline(i)

        echo CsvLineGetFields(l, b:csvColumn, b:csvColSpan)."\n"
        let i = i + 1
    endwhile
endfunction


" Echo all selected columns' values that match regex between line1 and line2,
" inclusive.
function! CsvMatch(line1, line2, regex)
    let linecount = a:line2 - a:line1 + 1
    let matchcount = 0

    let i = a:line1
    while i <= a:line2
        let l = getline(i)
        let f = CsvLineGetFields(l, b:csvColumn, b:csvColSpan)

        if CsvLineMatchesRegex1(f, a:regex)
            let c = CsvTextW(i, 4)
            echo c.' '.f

            let matchcount = matchcount + 1
        endif

        let i = i + 1
    endwhile

    echo matchcount.' matches on '.linecount.' lines'
endfunction


" Substitute all selected columns' values that match regex
" Arguments: line1, line2, regex, repl, [flags]
"
function! CsvSubstitute(line1, line2, ...)
    let regex = ''
    let repl = ''
    let flags = ''
    let replaces = 0
    let lcount = a:line2 - a:line1 + 1

    if a:0 >= 1
        let regex = a:1
    endif
    if a:0 >= 2
        let repl = a:2
    endif
    if a:0 >= 3
        let flags = a:3
    endif

    call CsvTimerStart()
    call CsvHiliteOff()

    let i = a:line1
    let j = 0
    while i <= a:line2
        let l = getline(i)
        let f1 = CsvLineGetFields(l, b:csvColumn, b:csvColSpan)
        let f2 = CsvLineSubstitute(f1, regex, repl, flags)

        if f1 !=# f2
            let l = CsvLineSetFields(l, b:csvColumn, f2)
            call setline(i, l)

            let replaces = replaces + 1
        endif

        call CsvTimerStat('Processed '.b:csvColSpan.' column(s) on '.j.' of '.lcount.' lines')

        let i = i + 1
        let j = j + 1
    endwhile

    echo replaces.' rows changed'
endfunction


function! CsvCopy(line1, line2, regex)
    let buf = ''
    let lcount = a:line2 - a:line1 + 1

    call CsvTimerStart()

    let i = a:line1
    let j = 0
    while i <= a:line2
        let l = getline(i)
        let f = CsvLineGetFields(l, b:csvColumn, b:csvColSpan)
        
        if CsvLineMatchesRegex1(f, a:regex)
            let buf = buf . "\n" . f
        endif

        call CsvTimerStat('Copied '.b:csvColSpan.' column(s) on '.j.' of '.lcount.' lines')

        let i = i + 1
        let j = j + 1
    endwhile
    let buf = strpart(buf, 1)

    call setreg(v:register, buf, 'b')
    echo 'Copied '.CsvTextColLine(b:csvColSpan, lcount)
endfunction


function! CsvDel(line1, line2, regex)
    let lcount = a:line2 - a:line1 + 1

    call CsvTimerStart()
    call CsvHiliteOff()

    let i = a:line1
    let j = 0
    while i <= a:line2
        let l = getline(i)
        let f = CsvLineGetFields(l, b:csvColumn, b:csvColSpan)
        
        if CsvLineMatchesRegex1(f, a:regex)
            let l = CsvLineDelCols(l, b:csvColumn, b:csvColSpan)
            call setline(i, l)
        endif

        call CsvTimerStat('Deleted '.b:csvColSpan.' column(s) on '.j.' of '.lcount.' lines')

        let i = i + 1
        let j = j + 1
    endwhile

    echo 'Deleted '.CsvTextColLine(b:csvColSpan, lcount)
endfunction


function! CsvCut(line1, line2, regex)
    let buf = ''
    let lcount = a:line2 - a:line1 + 1

    call CsvTimerStart()
    call CsvHiliteOff()

    let i = a:line1
    let j = 0
    while i <= a:line2
        let l = getline(i)
        let f = CsvLineGetFields(l, b:csvColumn, b:csvColSpan)

        if CsvLineMatchesRegex1(f, a:regex)
            let l = CsvLineDelCols(l, b:csvColumn, b:csvColSpan)
            call setline(i, l)

            let buf = buf . "\n" . f
        endif

        call CsvTimerStat('Cut '.b:csvColSpan.' column(s) on '.j.' of '.lcount.' lines')

        let i = i + 1
        let j = j + 1
    endwhile
    let buf = strpart(buf, 1)

    call setreg(v:register, buf, 'b')
    echo 'Cut '.CsvTextColLine(b:csvColSpan, lcount)
endfunction


" Paste to the column of the current cursor ('I'nsert mode), the column after
" or current cursor ('A'ppend mode), or paste-replace the currently selected
" column ('R'eplace mode).
function! CsvPaste(mode, line1, line2, regex)
    let reg = getreg(v:register)
    let rlc = CsvVarCountLines(reg)
    let slc = a:line2 - a:line1 + 1

    " No need to try to paste more data than is available in the register
    if slc > rlc
        let slc = rlc
    endif

    " Calculate the column to paste into
    let colnum = CsvGetColNum()
    if a:mode =~# 'v' && visualmode() ==# 'V'  " Linewise visual mode
        let colnum = b:csvColumn
    elseif a:mode =~# 'R'                      " Replace mode
        let colnum = b:csvColumn
    endif
    if a:mode =~# 'A'                          " Append mode
        let colnum = colnum + 1
    endif

    " Calculate how many loops we'll need
    let loopend = slc     " Insert only into selected region

    " ... unless we pasted with non-visual mode selection nor counting,
    " in which case everything in the buffer should be pasted, even
    " if it goes outside of the selected region (selection region in
    " this scenario would be the end of file.)
    if (a:mode =~# 'n') && (v:count == 0)
        let loopend = rlc
    endif

    " How many columns will we paste?
    let f = CsvVarGetLine(reg, 0)
    let colcount = CsvLineGetColCount(f)

    " Do we have regex, and if so, which column will we use to compare?
    let has_regex = strlen(a:regex)
    let regexcol = (a:mode =~# 'R') ? colnum : (b:csvColumn)

    call CsvTimerStart()
    call CsvHiliteOff()

    " Paste!
    let i = a:line1
    let j = 0
    while j < loopend
        let l = getline(i)
        let f = CsvVarGetLine(reg, j)
        let m = 1

        " If we are given a regex, paste only if selected column matches <regex>
        " (insert/append mode) or the target column matches regex (replace mode)
        if has_regex
            let lf = CsvLineGetField(l, regexcol)
            let m = CsvLineMatchesRegex1(lf, a:regex)
        endif

        if m
            " Paste fields only if there are fields to paste or the line
            " has data to paste to
            if strlen(f) || strlen(l)
                if a:mode =~# 'R'
                    let ln = CsvLineReplCols(l, colnum, b:csvColSpan, f)
                else
                    let ln = CsvLineInsCol(l, colnum, f)
                endif

                call setline(i, ln)
            endif

            call CsvTimerStat('Pasted '.colcount.' column(s) on '.j.' of '.loopend.' lines')
        endif

        let i = i + 1
        let j = j + 1
    endwhile

    " Hilite the pasted column and alert user
    let b:csvColumn = colnum
    call CsvHilite()
    call CsvColJump(b:csvColumn)
    echo 'Pasted '.CsvTextColLine(colcount, rlc)
endfunction


" Insert a field before the selected column between line1 and line2 using
" the specified text.
function! CsvInsert(mode, line1, line2, text)
    let lcount = a:line2 - a:line1 + 1
    let colnum = CsvGetColNum()

    " Linewise visual mode use selected column
    if a:mode =~# 'v' && visualmode() ==# 'V'
        let colnum = b:csvColumn
    endif

    " Append mode - column after the current column
    if a:mode =~# 'a'
        let colnum = colnum + 1
    endif

    call CsvTimerStart()
    call CsvHiliteOff()

    let i = a:line1
    let j = 0
    while i <= a:line2
        let l = getline(i)

        " Append column at the end of current line
        if a:mode =~# 'A'
            let colnum = CsvLineGetColCount(l)
        endif

        " Insert text only if there is data on the line
        if strlen(l) > 0
            let l = CsvLineInsCol(l, colnum, a:text)
            call setline(i, l)
        endif

        call CsvTimerStat('Inserted text on '.j.' of '.lcount.' lines')

        let i = i + 1
        let j = j + 1
    endwhile

    if a:mode =~# 'A'
        let l = getline(a:line1)
        let b:csvColumn = CsvLineGetColCount(l) - 1
    else
        let b:csvColumn = colnum
    endif

    call CsvHilite()
    call CsvColJump(b:csvColumn)
    echo 'Inserted text on '.CsvTextLine(lcount)
endfunction


" Replace the selected column between line1 and line2 using the specified text.
function! CsvReplace(line1, line2, text)
    let lcount = a:line2 - a:line1 + 1

    call CsvTimerStart()
    call CsvHiliteOff()

    let i = a:line1
    let j = 0
    while i <= a:line2
        let l = getline(i)

        " Replace text only if there is data on the line
        if strlen(l) > 0
            let l = CsvLineReplCols(l, b:csvColumn, b:csvColSpan, a:text)
            call setline(i, l)
        endif

        call CsvTimerStat('Replaced text on '.j.' of '.lcount.' lines')

        let i = i + 1
        let j = j + 1
    endwhile

    call CsvHilite()
    call CsvColJump(b:csvColumn)
    echo 'Replaced text on '.CsvTextLine(lcount)
endfunction


function! CsvInit()
    " Configuration controls
    command! -buffer -nargs=? Header :call CsvSetHeader(<args>)
    command! -buffer Csv :call CsvSetDelim(',')|set filetype=csv
    command! -buffer Psv :call CsvSetDelim('|')|set filetype=psv
    command! -buffer Tsv :call CsvSetDelim("\t")

    " Display
    map <buffer> <silent> <F2>  :<C-U>echo 'Col 1-2: '.CsvGetFields(0,2)<CR>
    map <buffer> <silent> <F3>  :<C-U>echo 'Col 1-3: '.CsvGetFields(0,3)<CR>
    map <buffer> <silent> <F4>  :<C-U>echo 'Col 1-4: '.CsvGetFields(0,4)<CR>
    nmap <buffer> <silent> ,_   :<C-U>call CsvSetStatLine(v:count)<CR>

    " Highlighted column control
    map <buffer> <silent>  ,.   :<C-U>call CsvSelectThisCol()<CR>
    map <buffer> <silent>  ,`   :<C-U>call CsvHiliteOff()<CR>

    " Navigation
    map  <buffer> <silent> ,'   :<C-U>call CsvJumpHome()<CR>
    map  <buffer> <silent> ,/   :<C-U>call CsvJumpSmart('f', v:count1, input(',/'))<CR>
    map  <buffer> <silent> ,?   :<C-U>call CsvJumpSmart('b', v:count1, input(',?'))<CR>
    nmap <buffer> <silent> ,n   :<C-U>call CsvJumpSmart(b:csvJumpDir, v:count1, '')<CR>
    nmap <buffer> <silent> ,N   :<C-U>call CsvJumpSmartR(b:csvJumpDir, v:count1, '')<CR>

    nmap <buffer> <silent> <C-h> :<C-U>call CsvLeft(v:count1)<CR>
    nmap <buffer> <silent> <C-j> :<C-U>call CsvDown(v:count1)<CR>
    nmap <buffer> <silent> <C-k> :<C-U>call CsvUp(v:count1)<CR>
    nmap <buffer> <silent> <C-l> :<C-U>call CsvRight(v:count1)<CR>

    nmap <buffer> <silent> ,<Left>  :<C-U>call CsvLeft(v:count1)<CR>
    nmap <buffer> <silent> ,<Down>  :<C-U>call CsvDown(v:count1)<CR>
    nmap <buffer> <silent> ,<Up>    :<C-U>call CsvUp(v:count1)<CR>
    nmap <buffer> <silent> ,<Right> :<C-U>call CsvRight(v:count1)<CR>

    " Column operation
    nmap <buffer> <silent> } :<C-U>call CsvIncSpan(v:count1)<CR>
    nmap <buffer> <silent> { :<C-U>call CsvDecSpan(v:count1)<CR>
    nmap <buffer> <silent> ,^ :<C-U>call CsvSetSpanToBegin()<CR>
    nmap <buffer> <silent> ,$ :<C-U>call CsvSetSpanToEnd()<CR>

    nmap <buffer> <silent> ,I :<C-U>call CsvInsert('In',CsvUtilNmapL1(),CsvUtilNmapL2(),input('Insert text: '))<CR>
    nmap <buffer> <silent> ,a :<C-U>call CsvInsert('an',CsvUtilNmapL1(),CsvUtilNmapL2(),input('Insert text: '))<CR>
    nmap <buffer> <silent> ,A :<C-U>call CsvInsert('An',CsvUtilNmapL1(),CsvUtilNmapL2(),input('Insert text: '))<CR>
    nmap <buffer> <silent> ,c :<C-U>call CsvReplace(CsvUtilNmapL1(),CsvUtilNmapL2(),input('Replace text: '))<CR>
    nmap <buffer> <silent> ,y :<C-U>call CsvCopy(CsvUtilNmapL1(),CsvUtilNmapL2(), '')<CR>
    nmap <buffer> <silent> ,x :<C-U>call CsvCut(CsvUtilNmapL1(),CsvUtilNmapL2(), '')<CR>
    nmap <buffer> <silent> ,X :<C-U>call CsvDel(CsvUtilNmapL1(),CsvUtilNmapL2(), '')<CR>
    nmap <buffer> <silent> ,P :<C-U>call CsvPaste('In',CsvUtilNmapL1(),CsvUtilNmapL2(),'')<CR>
    nmap <buffer> <silent> ,p :<C-U>call CsvPaste('An',CsvUtilNmapL1(),CsvUtilNmapL2(),'')<CR>
    nmap <buffer> <silent> ,O :<C-U>call CsvPaste('Rn',CsvUtilNmapL1(),CsvUtilNmapL2(),'')<CR>

    vmap <buffer> <silent> ,I :<C-U>call CsvInsert('Iv', line("'<"), line("'>"), input('Insert text: '))<CR>
    vmap <buffer> <silent> ,a :<C-U>call CsvInsert('av', line("'<"), line("'>"), input('Insert text: '))<CR>
    vmap <buffer> <silent> ,A :<C-U>call CsvInsert('Av', line("'<"), line("'>"), input('Insert text: '))<CR>
    vmap <buffer> <silent> ,c :<C-U>call CsvReplace(line("'<"), line("'>"), input('Replace text: '))<CR>
    vmap <buffer> <silent> ,y :<C-U>call CsvCopy(line("'<"), line("'>"), '')<CR>
    vmap <buffer> <silent> ,x :<C-U>call CsvCut(line("'<"), line("'>"), '')<CR>
    vmap <buffer> <silent> ,X :<C-U>call CsvDel(line("'<"), line("'>"), '')<CR>
    vmap <buffer> <silent> ,P :<C-U>call CsvPaste('Iv',line("'<"), line("'>"), '')<CR>
    vmap <buffer> <silent> ,p :<C-U>call CsvPaste('Av',line("'<"), line("'>"), '')<CR>
    vmap <buffer> <silent> ,O :<C-U>call CsvPaste('Rv',line("'<"), line("'>"), '')<CR>

    command! -buffer -nargs=1 CsvSpan :call CsvSetSpan(<args>)
    command! -buffer -range=% CsvEcho :call CsvEcho(<line1>,<line2>)
    command! -buffer -range=% -nargs=1 CsvMatch :call CsvMatch(<line1>,<line2>,<f-args>)
    command! -buffer -range=% -nargs=+ CsvSub :call CsvSubstitute(<line1>,<line2>,<f-args>)

    command! -buffer -range=% -nargs=1 CsvCopy :call CsvCopy(<line1>,<line2>,<f-args>)
    command! -buffer -range=% -nargs=1 CsvCut :call CsvCut(<line1>,<line2>,<f-args>)
    command! -buffer -range=% -nargs=1 CsvDel :call CsvDel(<line1>,<line2>,<f-args>)
    command! -buffer -range=% -nargs=1 CsvPaste :call CsvPaste('Ic',<line1>,<line2>,<f-args>)
    command! -buffer -range=% -nargs=1 CsvPasteA :call CsvPaste('Ac',<line1>,<line2>,<f-args>)
    command! -buffer -range=% -nargs=1 CsvPasteO :call CsvPaste('Rc',<line1>,<line2>,<f-args>)

    " Call the OnUnload handler when we unload the buffer
    autocmd BufUnload <buffer> call CsvOnUnload()

    " Call the OnLoad handler
    call CsvOnLoad()
endfunction


" A quick way to enable the csv macros
command! -buffer InitCsv :call CsvInit()

