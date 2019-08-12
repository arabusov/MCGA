(define src 
    (list "        LACC 0x43 0x39 ;;; this is comment"
          " label1:JMP 0x03"
          "        PUSH"
          "        POP"
          " LaBeL: HALT\t; this is another comment"))
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
(write (map (lambda (char) (char-in-digits? char))
            (string->list "0123456789ABCDEFGH")))
(write (map (lambda (char) (is-hex? char))
            (string->list "0123456789ABCDEFGH")))
(write (is-hex? #\H))
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
(write
  (map (lambda
         (str) (hex->int (string->list str)))
       (list "9" "A" "B" "F" "10" "100")))
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
    (list "LACA"  #x0a)
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
(define src-list
  (map (lambda (str)
         (let*(
               (cmd (split-str (string-upcase (throw-away-comment str)))))
           (list (remove-word-breaks (car cmd)) (process-instruction
                                                  (car (cdr cmd))))))
       src))
(write src-list)
(define output-program (list 1 0 0 12 0 0 9 8 7))
(define output (open-output-file "a.out"))
(map
  (lambda (byte)
    (write-char (integer->char byte) output))
  output-program)
(close-output-port output)
