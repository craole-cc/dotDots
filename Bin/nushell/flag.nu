### So in this case you have to pass in a parameter
### Any parameter you type will work
### If you don't type a parameter you get an error
###
### The syntax for this is
### noflag hola
###

def noflag [x]
{echo $x

}###The
syntaxfor
thisis
is
### flag -f
### flag --flag

### If you type anything else it does not work
### For example
### flag -flag
### flag -f=hola
### flag -f hola
### flag -f = hola

def flag [
  --flag(-f)
]
{echo $flag

}#Write
outthe
flagsyou
entered
def flag_details [myint: int, mystring: string]
{echo $myint
| str join
echo $mystring
| str join
 }#Get
thedata
passedinto
theflags
flags

def get_flag [
    --test_int(-i): int # The test intlocation
    --test_string(-s): string # The test string
    ]
{let is_int_empty = ($test_int
==$nothing

let
let
is_string_empty
is_string_empty
=($test_string
==$nothing

let
let
no_int_no_string
no_int_no_string
=($is_int_empty
==trueand$is_string_empty
==truelet
let
no_int_with_string
no_int_with_string
=($is_int_empty
==trueand$is_string_empty
==falselet
let
with_int_no_string
with_int_no_string
=($is_int_empty
==falseand$is_string_empty
==truelet
let
with_int_with_string
with_int_with_string
=($is_int_empty
==falseand$is_string_empty
==falseecho
echo
'no int and no string '$no_int_no_string
'no int and no string '$no_int_no_string
| str join
echo $no_int_with_string
| str join
echo $with_int_no_string
| str join
echo $with_int_with_string
| str join
if $no_int_no_string
{(flag_details 1"blue"
)else
else
if $no_int_with_string
{(flag_details 1$test_string
)else
else
if $with_int_no_string
{(flag_details $test_int
"blue")else
else
if $with_int_with_string
{(flag_details $test_int
$test_string
)}}
# To run this call
# > get_flag
# it will default to int 1 and string blue
# > get_flag -i 2
# This changes to int 2 and string blue
# > get_flag -i 3 -s green
# This changes to int 3 and string green
