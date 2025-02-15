### So in this case you have to pass in a parameter
### Any parameter you type will work
### If you don't type a parameter you get an error
###
### The syntax for this is
### noflag hola
###

def noflag [x]
{echo "$x"}### The syntax for this is
### flag -f
### flag --flag

### If you type anything else it does not work
### For example
### flag -flag
### flag -f=hola
### flag -f hola
### flag -f = hola

def flag [--flag(-f)]
{echo "$flag"}### Write out the flags you entered

def flag_details [myint: int, mystring: string]
{echo "$myint"echo "$mystring"}### Get the data passed into the flags

def get_flag [
    --test_int(-i): int,  # The test int
    --test_string(-s): string  # The test string
]
{let is_int_empty = ($test_int =="$nothing")let is_string_empty = ($test_string =="$nothing")let no_int_no_string = ($is_int_empty and$is_string_empty )let no_int_with_string = ($is_int_empty and(not$is_string_empty ))let with_int_no_string = ((not$is_int_empty )and$is_string_empty )let with_int_with_string = ((not$is_int_empty )and(not$is_string_empty ))echo $"no int and no string: ($no_int_no_string )"echo $"no int with string: ($no_int_with_string )"echo $"with int no string: ($with_int_no_string )"echo $"with int and string: ($with_int_with_string )"if $no_int_no_string {flag_details 1"blue"}else
if $no_int_with_string {flag_details 1$test_string }else
if $with_int_no_string {flag_details $test_int "blue"}else
if $with_int_with_string {flag_details $test_int $test_string }}
### To run this call
### > get_flag
### it will default to int 1 and string blue
### > get_flag -i 2
### This changes to int 2 and string blue
### > get_flag -i 3 -s green
### This changes to int 3 and string green
