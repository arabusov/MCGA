(define src 
    (list "LABEL1: LA 0x43 0x29 ;;; this is comment"
          " LaBeL: HALT ; this is another comment"))
(define findc
    (lambda (str symb pos)
        (if (>= pos (string-length str))
            -1
            (if (equal? symb (substring str pos (+ pos 1)))
                pos
                (findc str symb (+ pos 1))))))
(define throw-away-comment
  (lambda (str)
    (let*
      ((posc (findc str ";" 0))
       (instruction (if (>= posc 0)
                        (string-head str posc)
                        str)))
      instruction)))
(define split-str
  (lambda (str)
    (let* (
           (posc (findc str ":" 0))
           (label (if (>= posc 0)
                      (string-head str posc)
                    ""))
           (instruction (if (>= posc 0)
                            (string-tail str (+ posc 1))
                            str)))
      (list label instruction))))
(define remove-char
  (lambda (str symb pos)
    (if (>= pos (string-length str))
        str
        (let* (
               (posc (findc str symb pos)))
          (if (< posc 0)
              str
              (string-append (string-head str posc)
                             (remove-char (string-tail str (+ posc 1))
                                          symb (+ posc 1))))))))
(remove-char (car src) " " 0) 
(map (lambda (str) 
       (split-str (string-upcase (throw-away-comment str))))
     src)
(define output-program (list 1 0 0 12 0 0 9 8 7))
(define output (open-output-file "a.out"))
(map
  (lambda (byte)
    (write-char (integer->char byte) output))
  output-program)
(close-output-port output)
