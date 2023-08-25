# AWK

[One-liners](http://tuxgraphics.org/~guido/scripts/awk-one-liner.html)

## Built-In Variables

Awk’s built-in variables include the field variables—$1, $2, $3, and so on ($0 is the entire line) — that break a line of text into individual words or pieces called fields.

| Variable      | Description |
| ----------- | ----------- |
| NR | Keeps a current count of the number of input records. Remember that records are usually lines. Awk command performs the pattern/action statements once for each record in a file.|
| NF | Keeps a count of the number of fields within the current input record.|
| FS | Contains the field separator character which is used to divide fields on the input line. The default is “whitespace”, meaning space and tab characters. FS can be reassigned to another character (typically in BEGIN) to change the field separator.|
| RS | Stores the current record separator character. Since, by default, an input line is the input record, the default record separator character is a newline.|
| OFS | Stores the output field separator, which separates the fields when Awk prints them. The default is a blank space. Whenever print has several parameters separated with commas, it will print the value of OFS in between each parameter.|
| ORS | Stores the output record separator, which separates the output lines when Awk prints them. The default is a newline character. print automatically outputs the contents of ORS at the end of whatever it is given to print.|

```sh
echo "
/logs/tc0001/tomcat/tomcat7.1/conf/catalina.properties:app.env.server.name = demo.example.com
/logs/tc0001/tomcat/tomcat7.2/conf/catalina.properties:app.env.server.name = quest.example.com
/logs/tc0001/tomcat/tomcat7.5/conf/catalina.properties:app.env.server.name = www.example.com
" |
    awk -F'[/|=]' -vOFS='\t' '{print $3, $5, $NF}'
```

'/manager/ {print}'     => filter based on pattern
'NF { $1=$1; print }'   => remove all whitespace

printf "\n==>> awk <<===\n"
echo "$geekstut" |
    # awk '{print}'
    awk 'NF { $1=$1; print }'

echo "$tomcat" |
    awk -F'[/|=]' -vOFS='\t' '{print $3, $5, $NF}'
# awk -F'[/=]' '{print $3 "\t" $5 "\t" $8}'
