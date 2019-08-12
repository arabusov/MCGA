(define (get-src input-file src)
  (let*(
        (inp-line (read-line input-file)))
    (if (eof-object? inp-line)
        src
        (get-src input-file (append src (list inp-line))))))
(define input (open-input-file "source.asm"))
(define src (get-src input ()))
(define digits
  (string->list "0123456789"))
(define literals
  (string->list "ABCDEFGHIJKLMNOPQRSTUVWXYZ_"))
(define (power s n)
  (if (= 0 n)
      1
      (* s (power s (- n 1)))))
(define char-in-list?
  (lambda (char li pos)
    (if (>= pos (length li))
        #f
        (if (eq? char (list-ref li pos))
            #t
            (char-in-list? char li (+ pos 1))))))
(define char-in-literals?
  (lambda (char)
    (char-in-list? char literals 0)))
(define char-in-digits?
  (lambda (char)
    (char-in-list? char digits 0)))
(define is-hex?
  (lambda (char)
    (if (char-in-digits? char)
        #t
        (let*(
              (int (char->integer char))
              (aint (char->integer #\A))
              (fint (char->integer #\F)))
          (and (>= int aint) (<= int fint))))))
(define (check-list predicate li pos)
  (if (>= pos (length li))
      #t
      (if (predicate (list-ref li pos))
          (check-list predicate li (+ pos 1))
          #f)))
(define hex->int
  (lambda (li)
    (let*(
          (convli
            (map
              (lambda (char)
                (let*(
                      (cint (char->integer char))
                      (conv (if (char-in-digits? char)
                               (- cint
                                  (char->integer #\0))
                               (+ (- cint
                                  (char->integer #\A)) 10))))
                  conv))
              li))
          (passed? (check-list is-hex? li 0)))
      (if passed?
          (letrec
            (
             (f
               (lambda (ints num pos)
                 (if (>= pos (length ints))
                     num
                     (let*(
                           (a (list-ref ints pos))
                           (s (power 16 (- (- (length ints) pos) 1))))
                       (f convli (+ num (* a s))
                          (+ pos 1)))))))
            (f convli 0 0))
          -1)
      )))
(define short-opcodes
  (list
    (list "HALT" #x01)
    (list "PUSH" #x02)
    (list "POP"  #x03)
    (list "ADD"  #x04)
    (list "INV"  #x05)
    (list "INC"  #x06)
    (list "READ" #x07)
    (list "WRIT" #x08)
    (list "LADR" #x09)
    (list "LACA" #x0a)
    (list "SUB"  #x0b)))
(define long-opcodes
  (list
    (list "LACC" #x81)
    (list "LACM" #x82)
    (list "LMAC" #x83)
    (list "JMP"  #x84)
    (list "JZ"   #x85)))
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
(define split-str-by-symb
  (lambda (str symb)
    (let* (
           (posc (findc str symb 0))
           (label (if (>= posc 0)
                      (string-head str posc)
                    ""))
           (instruction (if (>= posc 0)
                            (string-tail str (+ posc 1))
                          str)))
      (list label instruction))))
(define split-str
  (lambda (str) (split-str-by-symb str ":")))
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
                                      symb 0)))))))
(define remove-spaces
  (lambda (str) (remove-char str " " 0)))
(define remove-tabs
  (lambda (str) (remove-char str "\t" 0)))
(define remove-word-breaks
  (lambda (str) (remove-spaces (remove-tabs str))))
(define find-instruction
  (lambda (op instr-set pos)
    (if (>= pos (length instr-set))
        -1
      (let*(
            (suggested-op (list-ref (list-ref instr-set pos) 0))
            (sug-op-len (string-length suggested-op)))
        (if (<= sug-op-len (string-length op))
            (if (equal? (substring op 0 sug-op-len) suggested-op)
                pos
              (find-instruction op instr-set (+ pos 1)))
          (find-instruction op instr-set (+ pos 1)))))))
(find-instruction "LACC" long-opcodes 0)
(define instruction-code
  (lambda (instr-set pos)
    (list-ref (list-ref instr-set pos) 1)))
(define parse-digits
  (lambda (rawli)
    (if (not (= (length rawli) 8))
        ()
      (let*(
            (a (eq? #\0 (list-ref rawli 0)))
            (b (eq? #\X (list-ref rawli 1)))
            (c (eq? #\0 (list-ref rawli 4)))
            (d (eq? #\X (list-ref rawli 5)))
            (arg1 (list (list-ref rawli 2) (list-ref rawli 3)))
            (arg2 (list (list-ref rawli 6) (list-ref rawli 7)))
            (e (is-hex? (car arg1)))
            (f (is-hex? (car (cdr arg1))))
            (g (is-hex? (car arg2)))
            (h (is-hex? (car (cdr arg2)))))
        (if (and a b c d e f g h)
            (list (hex->int arg1) (hex->int arg2))
          ())))))
(parse-digits (list #\0 #\X #\2 #\3 #\0 #\X #\A #\B))
(define parse-args
  (lambda (raw)
    (let*(
          (rawli (string->list raw))
          (fst (car rawli)))
      (if (eq? fst #\0)
          (parse-digits rawli)
          (list raw)))))
(define process-instruction
  (lambda (raw)
    (let*(
          (wo-spaces (remove-word-breaks raw))
          (pos-in-short (find-instruction wo-spaces short-opcodes 0)))
      (if (< pos-in-short 0)
          (let*(
                (pos-in-long (find-instruction wo-spaces long-opcodes 0)))
            (if (< pos-in-long 0)
                (list -1)
              (let*(
                    (mnem-cell (list-ref long-opcodes pos-in-long))
                    (mnem (car mnem-cell))
                    (mnem-code (car (cdr mnem-cell)))
                    (raw-len (string-length wo-spaces))
                    (mnem-len (string-length mnem))
                    (raw-args (substring wo-spaces mnem-len raw-len))
                    (args (parse-args raw-args))
                    (args-res (length args)))
                (if (> args-res 0)
                    (list mnem-code args)
                  -1))))
        (let*(
              (mnem-cell (list-ref short-opcodes pos-in-short))
              (mnem-code (car (cdr mnem-cell))))
          (list mnem-code))))))
(define enumerate-src
  (lambda (src enumerated-list curr-size pos)
    (if (>= pos (length src))
        enumerated-list
        (let*(
              (str (list-ref src pos))
              (no-comments (string-upcase (throw-away-comment str)))
              (cmd (split-str no-comments))
              (instr (process-instruction (second cmd)))
              (label (remove-word-breaks (car cmd)))
              (sursize (if (= (length instr) 2) 3 1))
              (item (list pos curr-size label instr))
              (return (append enumerated-list (list item))))
          (enumerate-src src return (+ curr-size sursize) (+ pos 1))))))
(define (find-label-pointer enum-src label)
  (second (find (lambda (item)
                  (let*(
                        (curr-label (third item)))
                    (equal? curr-label label))) enum-src)))
(define (substitute-labels enum-src bin-code pos)
  (if (>= pos (length enum-src))
      bin-code
      (let*(
            (item (list-ref enum-src pos))
            (instr (fourth item))
            (new-args
              (if (= (length instr) 2)
                  (let*(
                        (args (second instr)))
                    (if (= (length args) 1)
                        (let*(
                              (ref-to-instr (find-label-pointer
                                              enum-src (car args))))
                          (if ref-to-instr
                              (if (> ref-to-instr #xff)
                                  (list (bitwise-and #xff ref-to-instr)
                                        (arithmetic-shift -8 ref-to-instr))
                                  (list ref-to-instr 0))
                              (list -1 -1)))
                        args))
                  ()))
            (new-item (list (first item) (second item) (third item) (car instr)
                             new-args))
            (new-bin (append bin-code (list new-item))))
            (substitute-labels enum-src new-bin (+ pos 1)))))
(define enum-src (enumerate-src src () 0 0))
(define bin-code (substitute-labels enum-src () 0))
(define (make-out binary-list out-list pos)
  (if (>= pos (length binary-list))
      out-list
      (let*(
            (item (list-ref binary-list pos))
            (l (number->string (first item)))
            (instr (fourth item))
            (args (fifth item))
            (toappend
              (if (= (length args) 2)
                  (let*(
                        (a1 (first args))
                        (a2 (second args)))
                    (if (< a1 0)
                        (raise ((string-joiner) l ": wrong arg1"))
                      (if (< a2 0)
                          (raise ((string-joiner) l ": wrong arg2"))
                        (list instr a1 a2))))
                  (if (< instr 0)
                      (raise ((string-joiner) l ": wrong instr - "
                                              (number->string instr)))
                      (list instr)))))
        (make-out binary-list (append out-list toappend) (+ pos 1)))))
(define output-program (make-out bin-code () 0))
(define output (open-binary-output-file "a.out"))
(write-bytevector (list->bytevector output-program) output)
(close-output-port output)
