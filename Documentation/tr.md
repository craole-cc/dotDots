# tr

tr is a POSIX-compliant command-line utility used to translate, squeeze, and/or delete characters from standard input and send the result to standard output.  `STRING1` and `STRING2` specify arrays of characters `ARRAY1` and `ARRAY2` that control the action. It can perform operations like removing repeated characters, converting uppercase to lowercase, and basic character replacing and removing. Typically, it is used in combination with other commands through piping.

## How to Use the tr Command

```sh
tr [OPTION]... STRING1 [STRING2]
```

| Option | Description|
|---|---|
|`-c, -C, --compliment` | use the complement of ARRAY1 |
|`-d, --delete` | delete characters in ARRAY1, do not translate |
|`-s, --squeeze-repeats` | replace each sequence of a repeated character that is listed in the last specified ARRAY, with a single occurrence of that character |
|`-t, --truncate-set1` | first truncate ARRAY1 to length of ARRAY2 |

The syntax for the tr command is as follows:

**tr** accepts two sets of characters, usually of the same length, and replaces the characters of the first sets with the corresponding characters in the second set. A *SET* is basically a string of characters, including any special backslash-escaped characters.

In the following example, a message via the standard input is piped through the `tr` command which replaces each occurrence of `l` with `r`, `i` with `e`, and `n` with `d` by mapping characters from the first set with the matching ones from the second set.

```sh
printf "Result: "
printf "Learning linux is fun" | tr` 'lin' 'red'

Result: Leardedg redux es fud
```

Character sets can also be defined using ranges. For example:

```sh
printf "Result: "
printf "Learning linux is fun" | tr 'l-n' 'w-z'

Result: Learyiyg wiyux is fuy
```

When `-c | --complement` option is used, tr replaces all characters that are not in SET1. In the example below, all characters except `li` are replaced with the last character from the second set:

```sh
printf "Result: "
printf "Learning linux is fun" |  tr -c 'li' 'xyz'`

Result: zzzzzizzzlizzzzizzzzz
```

The `-d | --delete` option tells tr to delete characters specified in SET1. When deleting characters without squeezing, specify only one set. As shown in the example below, the command removes all instances of `l`, `i` and `z` but ignores the uppercase `L` as the `l` in the SET is lowercase.

```sh
printf "Result: "
printf "Learning linux is fun" | tr -d 'liz'

Result: Learnng nux s fun
```

In the following example, tr removes the repeated space characters:

```sh
> echo "GNU     \    Linux" | tr -s ' '
GNU \ Linux
```

The -s (--squeeze-repeats) option replaces a sequence of repeated occurrences with the character set in the last SET.

When SET2 is used the sequence of the character specified in SET1 is replaced with SET2.

```sh
> echo "GNU     \    Linux" | tr -s ' ' '_'
GNU_\_Linux
```

The -t (--truncate-set1) option forces tr to truncate SET1 to the length of SET2 before doing further processing.

By default, if SET1 is larger than SET2 tr will reuse the last character of SET2. Here is an example:
echo 'Linux ize' | tr 'abcde' '12'
Copy
The output shows that the character e from SET1 is matched with the latest character of SET2, which is 2:
Linux iz2
Copy
Now, use the same command with the -t option:

echo 'Linux ize' | tr -t 'abcde' '12'
Copy
Linux ize
Copy
You can see that the last three characters of the SET1 are removed. SET1 becomes ‘ab’, the same length as SET2, and no replacement is made.

Combining options
The tr command also allows you to combine its options. For example, the following command first replaces all characters except i with 0 and then squeezes the repeated 0 characters:

echo 'Linux ize' | tr -cs 'i' '0'
Copy
0i0i0
Copy
Tr Command Examples
In this section, we’ll cover a few examples of common uses of the tr command.
Convert lower case to upper case
Converting lower case to upper case or reverse is one of the typical use cases of the tr command. [:lower:] matches all lower case characters and [:upper:] matches all uppercase characters.

```sh
echo 'Linuxize' | tr '[:lower:]' '[:upper:]'
```

LINUXIZE
Copy
Instead of character classes, you can also use ranges:

echo 'Linuxize' | tr 'a-z' 'A-Z'
Copy
To convert upper case to lower case, simply switch the places of the sets.

Remove all non-numeric characters
The following command removes all non-numeric characters:

echo "my phone is 123-456-7890" | tr -cd [:digit:]
Copy
[:digit:] stands for all digit characters, and by using the -c option, the command removes all non-digit characters. The output will look like this:
1234567890
Copy
Put each word in a new line
To put each word in a new line, we need to match all non-alphanumerical characters and replace them with a new line:

echo 'GNU is an operating system' | tr -cs '[:alnum:]' '\n'
Copy
GNU
is
an
operating
system
Copy
Remove blank lines
To delete the blank lines simply squeeze the repetitive newline characters:

tr -s '\n' < file.txt > new_file.txt
Copy
In the command above we are using the redirection symbol < to pass the content of the file.txt to the tr command. The redirection > writes the output of the command to new_file.txt.

## Print $PATH directories on a separate line

The $PATH environmental variable is a colon-delimited list of directories that tells the shell which directories to search for executable files when you type a command.

To print each directory on a separate line we need to match the colon (:) and replace it with the new line:

```sh
echo $PATH | tr  ':' '\n'
```

Copy
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
Copy
Conclusion
tr is a command for translating or deleting characters.

Although very useful, tr can work only with single characters. For more complex pattern matching and string manipulation, you should use sed or awk .
If you have any questions or feedback, feel free to leave a comment.

tr
**terminal**

- [Linuxize](https://linuxize.com/post/linux-tr-command/)
