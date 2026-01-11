(local fennel (require :fennel))

(fn separator [title]
  (print (.. "\n=== " title " ===")))

(separator "Constructors & Types")

(local s (fennel.sym "foo"))
(print "Sym:" (fennel.view s) "type:" (type s) "meta:" (getmetatable s))
(local l (fennel.list (fennel.sym "+") 1 2))
(print "List:" (fennel.view l) "type:" (type l) "meta:" (getmetatable l))
(local seq (fennel.sequence 1 2 3))
(print "Seq:" (fennel.view seq) "type:" (type seq) "is-seq?" (fennel.sequence? seq))

(separator "Parser Output")

(fn parse-string [str]
  (let [parser (fennel.parser str)]
    (var (ok ast) (parser))
    (while ok
      (print "Parsed:" (fennel.view ast) "Type:" (type ast))
      (if (fennel.list? ast) (print "  It is a list"))
      (if (fennel.sym? ast) (print "  It is a sym"))
      (set (ok ast) (parser)))))

(parse-string "(+ 1 2) [3 4] :keyword symbol")

(separator "AST Mutation")
;; Lists are tables, so we should be able to mutate them
(local mut-list (fennel.list 1 2 3))
(table.insert mut-list 4)
(print "Mutated List:" (fennel.view mut-list))

(separator "Macro Helpers")
;; Testing if we can use these in macros (simulation)
(fn my-macro [ast]
  (if (fennel.list? ast)
      (fennel.list (fennel.sym "print") (fennel.view ast))
      ast))

(print "Macro transform of (+ 1 2):" (fennel.view (my-macro (fennel.list (fennel.sym "+") 1 2))))

(separator "Metadata Inspection")
;; We saw metadata access in fennel.lua: fennel.ast-source
(local sourced-sym (fennel.sym "foo" {:filename "test.fnl" :line 100 :col 5}))
(print "Sym with source:" (fennel.view sourced-sym))
(local src (fennel.ast-source sourced-sym))
(print "Source meta:" (fennel.view src))
(print "Filename:" src.filename "Line:" src.line)

;; Check if comments are preserved and inspectable
(local c (fennel.comment "hi"))
(print "Comment:" (fennel.view c) "is-comment?" (fennel.comment? c))
