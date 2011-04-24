" File:        TableHelper.vim
" By:          Salman Halim (salmanhalim@gmail.com)
" Description: Plugin to easily align text in columns (to make tables).
"
" Version 1.0:
"
" Initial version.
"
" This plugin helps with aligning text in columns, making the creation of tables easier. The process is simple:
"
" 1. Manually lay out one line of the table (the header, for example) and execute the command Gettabstopsfromcurrentline (there is a hotkey, in case you do this
" often) to have it parse the line and save the column definitions (per buffer).
"
" 2. Go to any other lines that are supposed to be in the table and either hit the hotkey on them one by one or visually select a range and hit the hotkey and
" they will all get realigned to match the header row.
"
" Caveat: these example may look horribly aligned if viewed with a proportional font.
"
" For example, given these three rows of text:
" 
" First name            Last name               Age
" ------  -----  -----
" John   Smith   28
" Jane             Doe          32
"
" If the first line is the one parsed for the columns, hitting the hotkey on the remaining lines yields:
"
" First name            Last name               Age
" ------                -----                   -----
" John                  Smith                   28
" Jane                  Doe                     32
"
" If you parse the last line instead you get this:
"
" First name       Last name    Age
" ------           -----        -----
" John             Smith        28
" Jane             Doe          32
"
" If you have the repeat.vim autoload plugin installed, the reformatting is repeatable on other lines.
"
" Requirements: the column text has to be separated by at least 2 spaces, both for the header line and for each line that is to be reformatted. For example:
"
" First name  Last name  Age
"
" Defines three columns, as does:
"
" First name          Last name            Age
"
" Options:
"
" g:TableHelper_truncateLongEntries (default 0): occasionally, you might have an entry in a table that is too long (say, you allocated 10 spaces for a column in
" the header but the text is actually 12 characters). This option determines how that is handled:
"
" - If 1, the entry gets truncated to fit. You will lose data, but the table will still line up (small price to pay!)
"
" - If 0, the entry is put in as is and allowed to comprise as many columns as needed. The rest of the text is simply aligned to the next column. You will
"   retain all your data, but will lose formatting.
"
" In practice, you should probably leave this value at 0. If you see misalignments, adjust your header row, recalculate the column stops, visually select your
" table and hit the hotkey and the whole thing will be realigned. If you start truncating fields, your only recourse will be the undo (u) key. (I only put this
" option in at all because it was fairly easy to implement the truncation!)
"
" g:TableHelper_columnMargin (default 2): how much space must there be between the end of one column's text and the start of the next before it's considered too
" long a column. Typically, you have to have some space between adjacent columns (or else, how can you tell where one column ends and the next begins). For
" example, if your header row and first row of data look like this:
"
" FName    LName  Age
" Jonathan  Smythe  28
"
" During reformat, the first column will be considered too long because there wouldn't be 2 spaces between Jonathan and Smythe (assuming
" g:TableHelper_columnMargin is set to 2--you can set it higher to get more space between columns). Thus, if you have truncation enabled
" (g:TableHelper_truncateLongEntries is 1), you'll get this:
"
" FName    LName  Age
" Jonatha  Smyth  28
"
" As it happens, the last name was too long, also. If you don't have truncation enabled, you get this:
"
" FName    LName  Age
" Jonathan        Smythe  28
"
" "Smythe" simply gets pushed under the next available column and then, since the number of header columns runs out, subsequent columns of text are simply
" placed as is, separated by g:TableHelper_columnMargin spaces.
" 
" This plugin requires at least two spaces between columns to be able to recognize them as distinct columns, so a value less than 2, while supported, will
" seriously jeopardize any attempts to reformat the table as all the text will run together (try setting it to 0...). If someone complains, I can force 2 as the
" minimum.
"
" If you have my getVar.vim, then you can set these options on a per window, buffer or tab basis, also. (otherwise, only on a global basis).
"
" Commands:
"
" Gettabstopsfromcurrentline: parses the current line for columns; probably best to call this from your header line, though you could also call it from the
" longest line in your table (and then use the alignment hotkey to have the header conform to this, also).
"
" Retabline: Reformats the specified lines (visually selected or the current line) so they conform the previously specified header line.
"
" Showtabstops: Displays the list of tab stops currently defined, if any.
"
" Mappings:
"
" <Plug>TableHelper_Gettabstopsfromcurrentline: executes Gettabstopsfromcurrentline (defaults to <leader><c-t>)
" 
" <Plug>TableHelper_Retabline: executes Retabline (defaults to <c-t>). May be called again after changing the truncation or column margin options to change the
" alignment of already formatted lines.
"
" The default hotkeys may be overridden in your vimrc.
"
" Tip: if you call Gettabstopsfromcurrentline on an empty line, you get no column definitions; then, when you try to reformat a line, it just ends up having the
" columns of text displayed in their entirety, separated by g:TableHelper_columnMargin spaces. For example, if g:TableHelper_columnMargin is 5, this line
"
" Jonathan                    Smythe  28
"
" becomes
"
" Jonathan     Smythe     28
"
" This might be useful for first laying out the longest line in the table, calling Gettabstopsfromcurrentline on it and then reformatting the entire table based
" on those column markers:
"
" FName        LName      Age
" -----        -----      ---
" Jonathan     Smythe     28
" Jon          Smith      32
"
" TODO: If there is interest, I could write a command to lay out a line with those spaces, ignoring column specifications to make it easier to lay a table out.
" Similarly, if there is interest, I could create the functionality to allow you to visually select a table and have the plugin deduce the longest columns
" across all rows and lay the table out automatically.

if ( exists( "g:TableHelper_loaded" ) )
  finish
endif

let g:TableHelper_loaded = 1

if ( !exists( "g:TableHelper_columnMargin" ) )
  let g:TableHelper_columnMargin = 2
endif

if ( !exists( "g:TableHelper_truncateLongEntries" ) )
  let g:TableHelper_truncateLongEntries = 0
endif

function! GetTabStopsFromLine( lineNumber )
  let line = getline( a:lineNumber )

  let b:TableHelper_columnStops = []
  let index                     = matchend( line, '\S', 0 )

  while ( index >= 0 )
    let b:TableHelper_columnStops += [ index ]

    let index = matchend( line, '\s\{2,}\S', index )
  endwhile
endfunction
com! Gettabstopsfromcurrentline call GetTabStopsFromLine( '.' )

function! RetabLine( startLine, endLine )
  if ( !exists( "b:TableHelper_columnStops" ) )
    echoerr "No tab stops have been defined. Please Gettabstopsfromcurrentline on the header line first."

    return
  endif

  let columnMargin        = g:TableHelper_columnMargin
  let truncateLongEntries = g:TableHelper_truncateLongEntries

  try
    let columnMargin = GetVar#GetVar( "TableHelper_columnMargin", g:TableHelper_columnMargin )
  catch
  endtry

  try
    let truncateLongEntries = GetVar#GetVar( "TableHelper_truncateLongEntries", g:TableHelper_truncateLongEntries )
  catch
  endtry

  let initialWhitespace = len( b:TableHelper_columnStops ) > 0 ? repeat( ' ', b:TableHelper_columnStops[ 0 ] - 1 ) : ''
  let lineNumber        = a:startLine

  while ( lineNumber <= a:endLine )
    let line         = getline( lineNumber )
    let marginSpaces = repeat( ' ', columnMargin )
    let tokens       = split( line, '\s\{2,}' )
    let numTokens    = len( tokens )

    let result = ''

    let result .= initialWhitespace

    let tokenCounter   = 0
    let columnCounter  = 0
    let originalColumn = -1

    while ( tokenCounter < numTokens )
      let token = tokens[ tokenCounter ]

      let tooLong = 0

      " If this isn't the last token and it isn't the last defined column and the new text is too long to fit in the current column width...
      if ( ( tokenCounter < ( numTokens - 1 ) ) && ( columnCounter < len( b:TableHelper_columnStops ) - 1 ) && ( ( strlen( result ) + strlen( token ) ) >= ( b:TableHelper_columnStops[ columnCounter + 1 ] - columnMargin ) ) )
        let tooLong = 1
      endif

      if ( tooLong )
        if ( truncateLongEntries == 1 )
          let result .= token

          " Long entries get truncated
          let result  = strpart( result, 0, b:TableHelper_columnStops[ columnCounter + 1 ] - columnMargin - 1 )
          let result .= marginSpaces

          let columnCounter += 1
        else
          " Long entries are put in, forcing the column count to keep going
          if ( originalColumn < 0 )
            let originalColumn = columnCounter
          endif

          let columnCounter += 1
          let tokenCounter  -= 1
        endif
      else
        let result .= token

        if ( columnCounter < ( len( b:TableHelper_columnStops ) - 1 ) )
          " Not too long, but we have more columns to consider, so have to pad the value with spaces to line up the next value correctly.
          let result .= repeat( ' ', b:TableHelper_columnStops[ columnCounter + 1 ] - strlen( token ) - b:TableHelper_columnStops[ originalColumn >= 0 ? originalColumn : columnCounter ] )

          let originalColumn = -1

          let columnCounter += 1
        elseif ( tokenCounter < ( numTokens - 1 ) )
          " We have more tokens than defined column stops so just separate remaining columns with two spaces.
          let result .= marginSpaces
        endif
      endif

      let tokenCounter += 1
    endwhile

    " If the line didn't change, no sense in having modification flags and the undo buffer changing.
    if ( result != line )
      call setline( lineNumber, result )
    endif

    let lineNumber += 1
  endwhile
endfunction
com! -range Retabline call RetabLine( <line1>, <line2> )

com! Showtabstops echo exists( "b:TableHelper_columnStops" ) ? string( b:TableHelper_columnStops ) : '<No tab stops have been set up.>'

if ( !hasmapto( '<Plug>TableHelper_Retabline', 'n' ) )
  nmap <silent> <c-t> <Plug>TableHelper_Retabline
endif

if ( !hasmapto( '<Plug>TableHelper_Retabline', 'v' ) )
  vmap <silent> <c-t> <Plug>TableHelper_Retabline
endif

if ( !hasmapto( '<Plug>TableHelper_Gettabstopsfromcurrentline', 'n' ) )
  nmap <silent> <leader><c-t> <Plug>TableHelper_Gettabstopsfromcurrentline
endif

" Since the mapping contains the LHS in the RHS (for repeat purposes), it's got to come after the hasmapto checks because Vim declares that such a mapping does
" actually exist.
noremap <Plug>TableHelper_Retabline :Retabline<cr>:silent! call repeat#set("\<Plug>TableHelper_Retabline")<cr>
nnoremap <Plug>TableHelper_Gettabstopsfromcurrentline :Gettabstopsfromcurrentline<cr>
