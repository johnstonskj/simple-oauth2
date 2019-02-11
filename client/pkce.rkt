#lang racket/base
;;
;; simple-oauth2 - oauth2/client/pkce.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide
 
 (except-out (struct-out pkce) make-pkce)
 
 create-challenge

 verifier-char?)

;; ---------- Requirements

(require racket/bool
         racket/contract
         racket/list
         racket/random
         racket/set
         file/sha1
         net/jwt/base64)

;; ---------- Implementation

(define-struct/contract pkce
  ([verifier bytes?]
   [challenge string?]
   [method (or/c "plain" "S256")]))

(define (char-range start end)
  ;; start and end -> (or/c char? natural?)
  (define (char-idx x) (if (char? x) (char->integer x) x))
  (for/list ([ch (in-range (char-idx start) (add1 (char-idx end)))])
    (integer->char ch)))

(define verifier-char-set
  ;; for quick lookup, here are the allowed ASCII allowed by PKCE
  ;;   unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
  ;;   ALPHA       = %x41-5A / %x61-7A
  ;;   DIGIT       = %x30-39
  (list->set
   (append
    (char-range #x41 #x5A) ; A...Z
    (char-range #x61 #x7A) ; a...z
    (char-range #x30 #x39) ; 0...9
    '(#\- #\. #\_ #\~))))

(define (verifier-char? ch)
  (and (char? ch)
       (set-member? verifier-char-set ch)))

(define (verifier-byte? ch)
  (verifier-char? (integer->char ch)))

(define (random-verifier length)
  (define (random-block)
    (crypto-random-bytes (* length 2)))
  (let next-block ([block (random-block)]
                   [verifier #""])
    (define filtered (list->bytes (filter verifier-byte? (bytes->list block))))
    (define sum (bytes-append verifier filtered))
    (define sum-length (bytes-length sum))
    (cond
      [(= sum-length length)
       sum]
      [(> sum-length length)
       (subbytes sum 0 length)]
      [else
       (next-block (random-block) sum)])))
  
(define (create-challenge [a-verifier #f])
  (define verifier
    (cond
      [(false? a-verifier)
       (random-verifier 128)]
      [(and (bytes? a-verifier)
            (>= (bytes-length a-verifier) 43)
            (<= (bytes-length a-verifier) 128))
       (unless (for/and ([ch (bytes->list a-verifier)]) (verifier-byte? ch))
         (error "invalid character code in verifier string"))
       a-verifier]
      [else (error "code verifier must be 43 to 128 byte string or #f")]))
  (define challenge (base64-url-encode (sha256-bytes verifier)))
  ; only support 'S256' option, no need for 'plain'
  (make-pkce verifier challenge "S256"))

;; ---------- Internal Tests

(module+ test
  (require rackunit)
  
  (define test-chars-ok "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_.~")
  (for-each (λ (ch) (check-true (verifier-char? ch) (format "char: ~a" ch))) (string->list test-chars-ok))

  (define test-chars-bad "!@#$%^&*()+={[}]|\\:;\"'<,>?/λßåœ∑®†¥πø∆˚˙ƒßå√ç")
  (for-each (λ (ch) (check-false (verifier-char? ch) (format "char: ~a" ch))) (string->list test-chars-bad))

  (define test-verifier (random-verifier 128))
  (check-equal? (bytes-length test-verifier) 128)
  (for-each (λ (ch) (check-true (verifier-byte? ch) (format "byte: ~a" ch))) (bytes->list test-verifier))

  (check-true (pkce? (create-challenge (string->bytes/latin-1 test-chars-ok))))

  (check-exn
   exn:fail?
   (λ ()
     (create-challenge "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRßTUVWXYZ-_.~"))
   "not bytes")

  (check-exn
   exn:fail?
   (λ ()
     (create-challenge (string->bytes/latin-1 "0123456789abcdefghijklmnopqrstuvwxyz")))
   "bytes to short")
  
  (check-exn
   exn:fail?
   (λ ()
     (create-challenge (string->bytes/latin-1 "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRßTUVWXYZ-_.~")))
   "invalid character 'ß' in string"))

