# SED One-liners

[Check out](https://www.grymoire.com/Unix/Sed.html#uh-20)

## Typical Use

Sed takes one or more editing commands and applies all of
them, in sequence, to each line of input. After all the commands have been applied to the first input line, that line is output and a second input line is taken for processing, and the cycle repeats. The following examples assume that input comes from the standard input device (i.e, the console, normally this will be piped input). One or more filenames can be appended to the command line if the input does not come from stdin. Output is sent to stdout (the screen). Thus:

```sh
# Piped input
cat filename | sed '10q'

# Same effect as pipe, but avoids a useless "cat"
sed '10q' filename

# redirects output to disk
sed '10q' filename > output_file
```

---

## Line Spacing

### Double-space

- Double space entire file

  ```sh
  sed G
  ```

- Double space a file which already has blank lines in it.
  > *Output file should contain no more than one blank line between lines of text.*

  ```sh
  sed '/^$/d;G'
  ```

- Undo double-spacing
  > *assumes even-numbered lines are always blank)*

  ```sh
  sed 'n;d'
  ```

### Triple-space

- Triple space entire file

  ```sh
  sed 'G;G'
  ```

### Blank Line

- Insert a blank line above every line which matches "regex"

  ```sh
  sed '/regex/{x;p;x;}'
  ```

- Insert a blank line below every line which matches "regex"

   ```sh
  sed '/regex/G'
  ```

- insert a blank line above and below every line which matches "regex"

  ```sh
  sed '/regex/{x;p;x;G;}'
  ```

## NUMBERING

- Number each line of a file (simple left alignment using a tab)
  > *To preserve margins '\t' is used. See note on '\t' at end of file*

  ```sh
  sed = filename | sed 'N;s/\n/\t/'
  ```

- Number each line of a file (number on left, right-aligned)

  ```sh
  sed = filename | sed 'N; s/^/     /; s/ *\(.\{6,\}\)\n/\1  /'

- Number each line of file, but only print numbers if line is not blank

   ```sh
  sed '/./=' filename | sed '/./N; s/\n/ /'
  ```

- Count lines (emulates "wc -l")

   ```sh
  sed -n '$='
  ```

## Text Conversion & Substitution

### DOS vs. Unix Line Endings

DOS uses carriage return and line feed ("\r\n") as a line ending, while Unix uses just line feed ("\n").

- In Unix Environment
   > Unix uses just line feed ("\n")
  - Convert DOS newlines (CR/LF) to Unix format

    ```sh
    sed 's/.$//'  # Assumes that lines end with CR/LF
    sed 's/^M$//' # In bash/tcsh, press Ctrl-V then Ctrl-M
    sed 's/\x0D$//'  # works on ssed, gsed 3.02.80 or higher
    ```

  - Convert Unix newlines (LF) to DOS format.

    ```sh
    sed "s/$/`echo -e \\\r`/"  # In ksh
    sed 's/$'"/`echo \\\r`/"   # In bash
    sed "s/$/`echo \\\r`/"     # In zsh
    sed 's/$/\r/'              # gsed 3.02.80 or higher
    ```

- DOS Environment
   > DOS uses carriage return and line feed ("\r\n")
  - Convert Unix newlines (LF) to DOS format.
    - Method 1

      ```sh
      sed "s/$//"
      ```

    - Method 2

      ```sh
      sed -n p
      ```

  - Convert DOS newlines (CR/LF) to Unix format.
      > *Can only be done with UnxUtils sed, version 4.0.7 or higher. The UnxUtils version can be identified by the custom "--text" switch which appears when you use the "--help" switch. Otherwise, changing DOS newlines to Unix newlines cannot be done with sed in a DOS environment. Use "tr" instead.*
    - UnxUtils sed v4.0.7 or higher

         ```sh
         sed "s/\r//" input > output
         ```

    - GNU tr version 1.22 or higher

         ```sh
         tr -d \r < input > output
         ```

### Whitespace

- Insert 5 blank spaces at the beginning of each line

  ```sh
  sed 's/^/     /'
  ```

- Remove leading whitespace (spaces, tabs) from start of each line

  ```sh
  sed 's/^[ \t]*//'
  ```

- Remove trailing whitespace (spaces, tabs) from end of each line

  ```sh
  sed 's/[ \t]*$//'
  ```

- Remove leading and trailing whitespace from each line

  ```sh
  sed 's/^[ \t]*//;s/[ \t]*$//'
   ```

  >*See note on '\t' at end of file*

### Alignment

- Align right with a column width of 79 characters
  > *Set colum width at 78 plus 1 space*

  ```sh
  sed -e :a -e 's/^.\{1,78\}$/ &/;ta'
  ```

- Align center in a 79-character column.
  > **Method 1**

  Spaces at the beginning of the line are significant, and trailing spaces are appended at the end of the line.

    ```sh
    sed  -e :a -e 's/^.\{1,77\}$/ & /;ta'
    ```

  > **Method 2**

  Spaces at the beginning of the line are discarded in centering the line, and no trailing spaces appear at the end of lines.

    ```sh
    sed  -e :a -e 's/^.\{1,77\}$/ &/;ta' -e 's/\( *\)\1/\1/'
    ```

### Substitution

- Substitute (find and replace) instances of "foo" with "bar" on each line.

  - All

     ```sh
     sed 's/foo/bar/g'
     ```

  - 1st

      ```sh
      sed 's/foo/bar/'
      ```

  - 4th

      ```sh
      sed 's/foo/bar/4'
      ```

  - Next-to-last

      ```sh
      sed 's/\(.*\)foo\(.*foo\)/\1bar\2/'
      ```

  - Last

      ```sh
      sed 's/\(.*\)foo/\1bar/'
      ```

  - Lines which contain "baz"

      ```sh
      sed '/baz/s/foo/bar/g'
      ```

  - Lines which do not contain "baz"

      ```sh
      sed '/baz/!s/foo/bar/g'
      ```

- Change "scarlet" or "ruby" or "puce" to "red"

  - Standard sed

      ```sh
      sed 's/scarlet/red/g;s/ruby/red/g;s/puce/red/g'
      ```

  - GNU sed

      ```sh
      gsed 's/scarlet\|ruby\|puce/red/g'
      ```

### Reverse

- Reverse order of lines (emulates "tac").
  >**NOTE:** *A Bug/feature in HHsed v1.5 causes blank lines to be deleted*
  - Method 1

     ```sh
     sed '1!G;h;$!d'
     ```

  - Method 2

     ```sh
     sed -n '1!G;h;$p'
     ```

- Reverse each character on the line (emulates "rev")

  ```sh
  sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//'
  ```

### Append

- Join pairs of lines side-by-side (like "paste")

  ```sh
  sed '$!N;s/\n/ /'
  ```

- Append the new line only if the previous line ends with a backslash.

  ```sh
  sed -e :a -e '/\\$/N; s/\\\n//; ta'
  ```

- If a line begins with an equal sign, append it to the previous line and replace the "=" with a single space

  ```sh
  sed -e :a -e '$!N;s/\n=/ /;ta' -e 'P;D'
  ```

- Add commas to numeric strings, changing "1234567" to "1,234,567"

  - Standard sed

     ```sh
     sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta'
     ```

  - GNU sed

     ```sh
     gsed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
     ```

- Add commas to numbers with decimal points and minus signs (GNU sed)

  ```sh
  gsed -r ':a;s/(^|[^0-9.])([0-9]+)([0-9]{3})/\1\2,\3/g;ta'
  ```

- Add a blank line every 5 lines (after lines 5, 10, 15, 20, etc.)

  - Standard sed

     ```sh
     sed 'n;n;n;n;G;'
     ```

  - GNU sed

     ```sh
     gsed '0~5G'
     ```

## Selective Printing

- First 10 lines of file (emulates behavior of "head")

   ```sh
   sed 10q
   ```

- First line of file (emulates "head -1")

   ```sh
   sed q
   ```

- Last 10 lines of a file (emulates "tail")

   ```sh
   sed -e :a -e '$q;N;11,$D;ba'
   ```

- Last 2 lines of a file (emulates "tail -2")

   ```sh
   sed '$!N;$!D'
   ```

- Last line of a file (emulates "tail -1")
  - Method 1

      ```sh
      sed '$!d'
      ```

  - Method 2

      ```sed
      sed -n '$p'
      ```

- Next-to-the-last line of a file

  - for 1-line files, print blank line

      ```ssh
      sed -e '$!{h;d;}' -e x
      ```

  - for 1-line files, print the line

     ```ssh
     sed -e '1{$q;}' -e '$!{h;d;}' -e x
     ```

  - for 1-line files, print nothing

     ```ssh
     sed -e '1{$d;}' -e '$!{h;d;}' -e x
     ```

- Lines which match regular expression (emulates "grep")
  - Method 1

      ```sh
      sed -n '/regexp/p'
      ```

  - Method 2

      ```sh
      sed '/regexp/!d'
      ```

- Lines which do NOT match regexp (emulates "grep -v")
  - Method 1, corresponds to above

      ```sh
      sed -n '/regexp/!p'
      ```

  - Method 2, simpler syntax

      ```sh
      sed '/regexp/d'
      ```

- Line immediately before a regexp, but not the line containing the regexp

   ```sh
   sed -n '/regexp/{g;1!p;};h'
   ```

- Line immediately after a regexp, but not the line containing the regexp

   ```sh
   sed -n '/regexp/{n;p;}'
   ```

- Line of context before and after regexp, with line number indicating where the regexp occurred (similar to "grep -A1 -B1")

   ```sh
   sed -n -e '/regexp/{=;x;1!p;g;$!N;p;D;}' -e h
   ```

- Lines containing AAA and BBB and CCC (in any order)

   ```sh
   sed '/AAA/!d; /BBB/!d; /CCC/!d'
   ```

- Lines containing AAA and BBB and CCC (in that order)

   ```sh
   sed '/AAA.*BBB.*CCC/!d'
   ```

- Lines containing AAA or BBB or CCC (emulates "egrep")
  - Standard

      ```sh
      sed -e '/AAA/b' -e '/BBB/b' -e '/CCC/b' -e d
      ```

  - GNU

      ```sh
      gsed '/AAA\|BBB\|CCC/!d'
      ```

- Paragraph if it contains AAA (blank lines separate paragraphs
   > *HHsed v1.5 must insert a 'G;' after 'x;' in the next 3 scripts below*

   ```sed
   sed -e '/./{H;$!d;}' -e 'x;/AAA/!d;'
   ```

- Paragraph if it contains AAA and BBB and CCC (in any order)

   ```sh
   sed -e '/./{H;$!d;}' -e 'x;/AAA/!d;/BBB/!d;/CCC/!d'
   ```

- Paragraph if it contains AAA or BBB or CCC
  - Standard

      ```sh
      sed -e '/./{H;$!d;}' -e 'x;/AAA/b' -e '/BBB/b' -e '/CCC/b' -e d
      ```

  - GNU

      ```sh
      gsed '/./{H;$!d;};x;/AAA\|BBB\|CCC/b;d'
      ```

- Lines of 65 characters or longer

   ```sh
   sed -n '/^.\{65\}/p'
   ```

- Lines of less than 65 characters
  - Method 1, corresponds to above

      ```sh
      sed -n '/^.\{65\}/!p'
      ```

  - Method 2, simpler syntax

      ```sh
      sed '/^.\{65\}/d'
      ```

- Section from regular expression to end of file

   ```sh
   sed -n '/regexp/,$p'
   ```

- Section based on line numbers (lines 8-12, inclusive)
  - Method 1

      ```sh
      sed -n '8,12p'
      ```

  - Method 2

      ```sh
      sed '8,12!d'
      ```

- Line number 52
  - Method 1

      ```sh
      sed -n '52p'
      ```

  - Method 2

      ```sh
      sed '52!d'
      ```

  - Method 3, efficient on large files

      ```sh
      sed '52q;d'
      ```

- Beginning at line 3, print every 7th line
  - Standard

      ```sh
      sed -n '3,${p;n;n;n;n;n;n;}'
      ```

  - GNU

      ```sh
      gsed -n '3~7p'
      ```

- Section between two regular expressions (inclusive)

   ```sh
   sed -n '/Iowa/,/Montana/p'    # case sensitive
   ```

- All EXCEPT section between 2 regular expressions

   ```sh
   sed '/Iowa/,/Montana/d'    # case sensitive
   ```

## Selective Deletion

- Parentheses:

```sh
sed 's/[()]//g'
```

- Parentheses and contained text:

```sh
sed 's/([^)]*)//g;s/  / /g'
```

- Nested Parentheses and text:

```sh
sed -e :A -e 's/([^()]*)//;tA' -e 's/  / /g'
```

- Duplicate, consecutive lines (emulates "uniq"). The first line in a set of duplicate lines is kept, the rest are deleted.

   ```sh
   sed '$!N; /^\(.*\)\n\1$/!P; D'
   ```

- Duplicate, nonconsecutive lines from a file. Beware not to overflow the buffer size of the hold space, or else use GNU sed.

   ```sh
   sed -n 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P'
   ```

- All lines except duplicate lines (emulates "uniq -d").
sed '$!N; s/^\(.*\)\n\1$/\1/; t; D'

- First 10 lines

   ```sh
   sed '1,10d'
   ```

- Last line

   ```sh
   sed '$d'
   ```

- Last 2 lines

   ```sh
   sed 'N;$!P;$!D;$d'
   ```

- Last 10 lines
  - Method 1

      ```sh
      sed -e :a -e '$d;N;2,10ba' -e 'P;D'
      ```

  - Method 2

      ```sh
      sed -n -e :a -e '1,10!{P;N;D;};N;ba'
      ```

- Every 8th line
  - Standard

      ```sh
      sed 'n;n;n;n;n;n;n;d;'
      ```

  - GNU

      ```sh
      gsed '0~8d'
      ```

- Lines matching pattern

   ```sh
   sed '/pattern/d'
   ```

- Blank lines from a file (same as "grep '.' ")
  - Method 1

      ```sh
      sed '/^$/d'
      ```

  - Method 2

      ```sh
      sed '/./!d'
      ```

- Consecutive blank lines except the first (emulates "cat -s")
  - Method 1, allows 0 blanks at top, 1 at EOF

      ```sh
      sed '/./,/^$/!d'
      ```

  - Method 2, allows 1 blank at top, 0 at EOF

      ```sh
      sed '/^$/N;/\n$/D'
      ```

- Consecutive blank lines except the first 2

   ```sh
   sed '/^$/N;/\n$/N;//D'
   ```

- Leading blank lines at top of file

   ```sh
   sed '/./,$!d'
   ```

- Trailing blank lines at end of file
  - Standard

      ```sh
      sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
      ```

  - GNU *(except for gsed 3.02.\*)*

      ```sh
      sed -e :a -e '/^\n*$/N;/\n$/ba'
      ```

- Last line of each paragraph

   ```sh
   sed -n '/^$/{p;h;};/./{x;/./p;}'
   ```

## Special Application

### New Roff & Overstrike in Man Pages

> The 'echo' command may need an -e switch if you use Unix System V or bash shell

- Double quotes required for Unix environment

  ```sh
  sed "s/.`echo \\\b`//g"
  ```

- In bash/tcsh, press Ctrl-V and then Ctrl-H

  ```sh
  sed 's/.^H//g'
  ```

- Hex expression for sed 1.5, GNU sed, ssed

  ```sh
  sed 's/.\x08//g'
  ```

### Usenet/e-mail

- Message header. Deletes everything after first blank line

   ```sh
   sed '/^$/q'
   ```

- Message body. Deletes everything after first blank line

   ```sh
   sed '1,/^$/d'
   ```

- Subject header, but remove initial "Subject: " portion

   ```sh
   sed '/^Subject: */!d; s///;q'
   ```

- Return address header

   ```sh
   sed '/^Reply-To:/q; /^From:/h; /./d;g;q'
   ```

- Parse the email address from the 1-line of the return address header *(see preceding script)*

   ```sh
   sed 's/ *(.*)//; s/>.*//; s/.*[:<] *//'
   ```

- Quotes
  - Add a leading angle bracket and space to each line (quote a message)

      ```sh
      sed 's/^/> /'
      ```

  - Delete leading angle bracket & space from each line (unquote a message)

      ```sh
      sed 's/^> //'
      ```

- HTML
  - Remove most HTML tags (accommodates multiple-line tags)

   ```sh
   sed -e :a -e 's/<[^>]*>//g;/</N;//ba'
   ```

  - Extract multi-part uuencoded binaries, removing extraneous header info, so that only the uuencoded portion remains. Files passed to sed must be passed in the proper order.
    - Version 1, can be entered from the command line;

      ```sh
      sed '/^end/,/^begin/d' file1 file2 ... fileX | uudecode
      ```

    - version 2 can be made into an executable Unix shell script. (Modified from a script by Rahul Dhesi.)

      ```sh
      sed '/^end/,/^begin/d' "$@" | uudecode
      ```

- Sort
  - Sort paragraphs alphabetically. Paragraphs are separated by blank lines.
    - Standard

      ```sh
      sed '/./{H;d;};x;s/\n/={NL}=/g' file | sort | sed '1s/={NL}=//;s/={NL}=/\n/g'
      ```

    - GNU, uses \v for vertical tab, or any unique char will do.

      ```sh
      gsed '/./{H;d};x;y/\n/\v/' file | sort | sed '1s/\v//;y/\v/\n/'
      ```

- Archive
  - Zip each .txt file individually, deleting the source file and setting the name of each .ZIP file to the basename of file.
      > *Under DOS: the "dir /b" switch returns bare filenames in all caps*

      ```sh
      echo @echo off >output.bat
      dir /b *.txt | sed "s/^\(.*\)\.TXT/pkzip -mo \1 \1.TXT/" >>output.bat
      ```

---

For additional syntax instructions, including the way to apply editing commands from a disk file instead of the command line, consult "sed & awk, 2nd Edition," by Dale Dougherty and Arnold Robbins (O'Reilly, 1997; <http://www.ora.com>), "UNIX Text Processing," by Dale Dougherty and Tim O'Reilly (Hayden Books, 1987) or the tutorials by Mike Arst distributed in U-SEDIT2.ZIP (many sites). To fully exploit the power of sed, one must understand "regular expressions." For this, see "Mastering Regular Expressions" by Jeffrey Friedl (O'Reilly, 1997). The manual ("man") pages on Unix systems may be helpful (try "man
sed", "man regexp", or the subsection on regular expressions in "man ed"), but man pages are notoriously difficult. They are not written to teach sed use or regexps to first-time users, but as a reference text for those already acquainted with these tools.

## Quoting Syntax

The preceding examples use single quotes ('...') instead of double quotes ("...") to enclose editing commands, since sed is typically used on a Unix platform. Single quotes prevent the Unix shell from interpreting the dollar sign ($) and backquotes (`...`), which are expanded by the shell if they are enclosed in double quotes. Users of the "csh" shell and derivatives will also need to quote the exclamation mark (!) with the backslash (i.e., \!) to
properly run the examples listed above, even within single quotes.
Versions of sed written for DOS invariably require double quotes
("...") instead of single quotes to enclose editing commands.

## Use of '\t'

For clarity in documentation, we have used the expression '\t' to indicate a tab character (0x09) in the scripts. However, most versions of sed do not recognize the '\t' abbreviation, so when typing these scripts from the command line, you should press the TAB key instead. '\t' is supported as a regular expression meta character in awk, perl, and HHsed, sedmod, and GNU sed v3.02.80.

## Versions

Versions of sed do differ, and some slight syntax variation is to be expected. In particular, most do not support the use of labels (:name) or branch instructions (b,t) within editing commands, except at the end of those commands. We have used the syntax which will be portable to most users of sed, even though the popular GNU versions of sed allow a more succinct syntax. When the reader sees a fairly long command such as this:

```sh
sed -e '/AAA/b' -e '/BBB/b' -e '/CCC/b' -e d
```

it is heartening to know that GNU sed will let you reduce it to:

```sh
sed '/AAA/b;/BBB/b;/CCC/b;d'
```

or even

```sh
sed '/AAA\|BBB\|CCC/b;d'
```

In addition, remember that while many versions of sed accept a command like "/one/ s/RE1/RE2/", some do NOT allow "/one/! s/RE1/RE2/", which contains space before the 's'. Omit the space when typing the command.

## Optimization

If execution speed needs to be increased (due to large input files or slow processors or hard disks), substitution will be executed more quickly if the "find" expression is specified before
giving the "s/.../.../" instruction. Thus:

```sh
# Standard replace command
sed 's/foo/bar/g' filename

# Executes more quickly
sed '/foo/ s/foo/bar/g' filename

# Shorthand sed syntax
sed '/foo/ s//bar/g' filename
```

On line selection or deletion in which you only need to output lines from the first part of the file, a "quit" command (q) in the script will drastically reduce processing time for large files. Thus:

```sh
# Print line nos. 45-50 of a file
sed -n '45,50p' filename

# Same, but executes much faster
sed -n '51q;45,50p' filename
```

---

## Source

>**USEFUL ONE-LINE SCRIPTS FOR SED (Unix stream editor)** |
>*Dec. 29, 2005 | v. 5.5*

|||
|---|---|
|Language|Link|
|English      |<http://sed.sourceforge.net/sed1line.txt>  |
|Chinese      |<http://sed.sourceforge.net/sed1line_zh-CN.html> |
|Czech        |<http://sed.sourceforge.net/sed1line_cz.html>  |
|Dutch        |<http://sed.sourceforge.net/sed1line_nl.html>  |
|French       |<http://sed.sourceforge.net/sed1line_fr.html>  |
|German       |<http://sed.sourceforge.net/sed1line_de.html>  |
|Italian      |(pending)  |
|Portuguese   |<http://sed.sourceforge.net/sed1line_pt-BR.html>
|Spanish      |(pending)  |

If you have any additional scripts to contribute or if you find errors in this document please send an *[email](pemente@northpark.edu)* to the compiler, indicating the:

  1. Version of sed used
  2. Operating system it was compiled for
  3. Nature of the problem.

To qualify as a one-liner, the command line must be 65 characters or less. Various scripts in this file have been written or contributed by:

| Contributor          | Role                              |
| ---                  |  ---                              |
| Al Aab               |   Founder of "seders" list        |
| Edgar Allen          |   Various                         |
| Yiorgos Adamopoulos  |   Various                         |
| Dale Dougherty       |   Author of "sed & awk"           |
| Carlos Duarte        |   Author of "do it with sed"      |
| Eric Pement          |   Author of this document         |
| Ken Pizzini          |   Author of GNU sed v3.02         |
| S.G. Ravenhall       |   Great de-html script            |
| Greg Ubben           |   Many contributions & much help  |
| Craig Cole           |   Converted to markdown           |
