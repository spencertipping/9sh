# 9sh commands
`ls /usr/bin` and `ls //db` are both called `ls`, but they have different grammars and are executed differently. This requires 9sh to support not just command polymorphism but also _parse polymorphism,_ both governed by the PWD. This is nontrivially complex because polymorphic grammars can modify the parse points. You could imagine, for example:

``` sh
$ cat file | grep foo | bar > 10 | zstd > file.zst
#          |---------------------| <- parse 1: | is infix or
#          |----------|----------| <- parse 2: | is pipe
```

It might seem unreasonable for commands to overload `|`, but that flexibility improves interactive systems:

``` sh
$ @py x = 10
$ @py y = 20
$ @py x | y                     # probably not a shell pipe
@py: 30
$ @py x | wc -c                 # probably a shell pipe
@py: 3
$ @gemini explain `ls | wc -l`  # not a shell pipe
@gemini: ...
$
```
