# csv-vim

vim macros for editing csv files.

![screenshot](https://github.com/markuskimius/csv-vim/blob/master/doc/screenshot.gif)


## Installation

Simply clone the repository into a vim pack directory.  E.g.,

```sh
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/markuskimius/csv-vim.git
```

The macros are enabled automatically when editing a file with the extensions
.csv, .psv, or tsv.  They can also be enabled manually using `:CsvInit`,
`:PsvInit`, or `:TsvInit`.


## Usage

Navigation:

* `<Ctrl>-h` or `<Ctrl>-<Left>` to move the cursor to the left column
* `<Ctrl>-l` or `<Ctrl>-<Right>` to move the cursor to the right column
* `<Ctrl>-j` or `<Ctrl>-<Down>` to move the cursor to the same column on the next row.
* `<Ctrl>-k` or `<Ctrl>-<Up>` to move the cursor to the same column on the previous row.

Column Selection:

* `,.` to select the column with the cursor on it.
* `}` to expand the selection by one extra column.
* `{` to reduce the selection by one fewer column.

Editing:

* `,y` to copy the selected column(s).
* `,x` to cut the selected column(s).
* `,P` to paste the selected column(s) to the column with the cursor on it.
* `,p` to paste the selected column(s) to the column after the column with the cursor on it.

The edit operations may specify a buffer.  They may also specify a range to
operate only on a subset of rows.

Searching:

* `,/<regex>` to move the cursor and the selection to the next column whose header matches `<regex>`.
* `,?<regex>` to move the cursor and the selection to the previou column whose header matches `<regex>`.
* `,n` to repeat the search.
* `,N` to repeat the search in the reverse direction.

See `:help csv` for the complete list of commands.


## Syntax Highlighting

The package also includes syntax highlighting of csv, psv, and tsv files.


## License

[Apache 2.0]



[Apache 2.0]: <https://github.com/markuskimius/csv-vim/blob/master/LICENSE>

