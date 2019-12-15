# csv-vim

vim macros for editing csv files.


## Installation

Simply clone the repository into a vim pack directory.  E.g.,

```sh
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/markuskimius/csv-vim.git
```

The macros are enabled automatically when editing a file with the extension
.csv, .psv, or tsv.  It can also be enabled manually using `:InitCsv`.

Regardless of the filename's extension, the delimiter is auto-detected from a
comma, a pipe, or a tab.  The delimiter can be force-changed with the commands
`:Csv`, `:Psv`, `:Tsv`, or to an arbitrary character using
`:SetDelim("<delim>")`.


## Usage

Navigation:

* `<Ctrl>-h` or `<Ctrl>-<Left>` to move to the column to the left
* `<Ctrl>-l` or `<Ctrl>-<Right>` to move to the column to the right
* `<Ctrl>-j` or `<Ctrl>-<Down>` to move to the same column on the next row.
* `<Ctrl>-k` or `<Ctrl>-<Up>` to move to the same column on the previous row.

Column Selection:

* `<Ctrl>-.` to select the column with the cursor.
* `}` to expand the selection by one extra column.
* `{` to reduce the selection by one fewer column.

Editing:

* `<Ctrl>-y` to copy the selected column(s).
* `<Ctrl>-x` to cut the selected column(s).
* `<Ctrl>-P` to paste the selected column(s) to the column with the cursor.
* `<Ctrl>-p` to paste the selected column(s) to the column after the column with the cursor.

The operations may specify a buffer.  They may also specify a range to operate
only on a subset of rows.

There are many more commands.  See `:help csv` for the complete list.


## Syntax Highlighting

The package also includes syntax highlighting of csv, psv, and tsv files.
Unlike the macros, syntax highlighting is not auto-detected but set from the
filename's extension.  It can be changed manually using `:set
filetype=<extension>`.


## License

[Apache 2.0]


[Apache 2.0]: <https://github.com/markuskimius/csv-vim/blob/master/LICENSE>

