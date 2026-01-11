(local fennel (require :fennel))

(fn parse-one [str]
  (let [parser (fennel.parser str)]
    (match (parser)
      (true val) val
      _ nil)))

(print "\n=== Keyword vs String Experiment ===")
(local kw (parse-one ":foo"))
(local str (parse-one "\"foo\""))

(print "Keyword :foo parses to:" (fennel.view kw) "Type:" (type kw))
(print "String \"foo\" parses to:" (fennel.view str) "Type:" (type str))

(if (= kw str)
    (print "They are EQUAL")
    (print "They are DIFFERENT"))

(print "\n=== Metadata check ===")
;; Maybe they have different metadata?
;; Primitives in Lua (strings, numbers) can't hold metatables or fields.
;; So unless they are wrapped tables, they can't carry unique metadata if they are equal values.
;; But let's check if fennel.ast-source returns anything different (maybe it uses a weak table registry?)

(local src-kw (fennel.ast-source kw))
(local src-str (fennel.ast-source str))

(print "Source of keyword:" (fennel.view src-kw))
(print "Source of string:" (fennel.view src-str))
