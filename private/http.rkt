#lang racket/base
;;
;; simple-oauth2 - private/http.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide (all-defined-out))

;; ---------- Requirements

(require racket/set
         racket/string)

;; ---------- Implementation

(define (method-name sym)
  (cond
    [(set-member? (set 'get 'head 'put 'post 'delete 'options) sym)
     (string-upcase (symbol->string sym))]
    [else #f]))

(define (header-name/x sym)
  (string-append "X-" (header-name sym)))

(define (header-name sym)
  (cond
    [(symbol? sym)
     (string-titlecase (symbol->string sym))]
    [else #f]))

(define (make-header-parameter sym value)
  (if (symbol? sym)
      (format "; ~a=~a" sym value)
      #f))

(define (make-header-parameters parameter-hash)
  (apply
   string-append
   (hash-map parameter-hash (λ (k v) (make-header-parameter k v)))))

(define (make-header-options lst)
  (string-join (map symbol->string lst) ", "))

(define (make-header-string sym value [parameters (hash)])
  (format "~a: ~a~a"
          (header-name sym)
          value
          (make-header-parameters parameters)))

(define (make-auth-header secret [type 'basic] [parameters (hash)])
  (format "~a: ~a ~a~a"
          (header-name 'authorization)
          (string-titlecase (symbol->string type))
          secret
          (make-header-parameters parameters)))

(define (make-media-type major minor [parameters (hash)])
  (format "~a/~a~a"
          major
          minor
          (make-header-parameters parameters)))
          
(define (media-type sym)
  (cond
    [(set-member? (set 'css 'html 'xml 'plain 'csv) sym)
     (make-media-type 'text sym)]
    [(set-member? (set 'javascript 'json 'zip 'pdf 'sql 'graphql) sym)
     (make-media-type 'application sym)]
    [(equal? sym 'form-urlencoded)
     (make-media-type 'application 'x-www-form-urlencoded)]
    [(set-member? (set 'png 'jpeg 'gif 'tiff 'svg) sym)
     (make-media-type 'image sym)]
    [else #f]))

(define (error-code sym)
  (cond
    [(equal? sym 'ok) 200]
    [(equal? sym 'bad-request) 400]
    [(equal? sym 'server-error) 500]
    [(equal? sym 'last-error) 599]
    [else #f]))

(define (error-message sym)
  (cond
    [(equal? sym 'ok) "OK"]
    [(equal? sym 'bad-request) "Bad Request"]
    [(equal? sym 'server-error) "Internal Server Error"]
    [else #f]))

(define (error-message/bytes sym)
  (string->bytes/latin-1 (error-message sym)))

;; ---------- Internal tests

(module+ test
  (require rackunit)

  ;; error-code
  (check-equal? (error-code 'ok) 200)
  (check-false (error-code 'conflict))

  ;; error-message
  (check-equal? (error-message 'ok) "OK")
  (check-false (error-message 'conflict))
  (check-true (bytes? (error-message/bytes 'ok)))

  ;; method-name
  (check-equal? (method-name 'get) "GET")
  (check-false (method-name 'patch))

  ;; header-name
  (check-equal? (header-name 'content-type) "Content-Type")
  (check-equal? (header-name 'x-my-header) "X-My-Header")
  (check-equal? (header-name/x 'my-header) "X-My-Header")
  (check-false (header-name "Date"))

  ;; make-header-parameter
  (check-equal? (make-header-parameter 'max 200) "; max=200")

  ;; make-header-parameters
  (check-equal? (make-header-parameters (hash 'max 200)) "; max=200")
  (check-equal? (make-header-parameters (hash 'min 100 'max 200)) "; min=100; max=200")

  ;; make-header-options
  (check-equal? (make-header-options '(one two three)) "one, two, three")
  
  ;; make-header-string
  (check-equal? (make-header-string 'content-type "text/plain") "Content-Type: text/plain")

  ;; make-auth-header
  (check-equal? (make-auth-header "secret-string") "Authorization: Basic secret-string")

  ;; make-media-type
  (check-equal? (make-media-type 'text 'plain) "text/plain")
  (check-equal? (make-media-type 'text 'plain (hash 'lang "en-US")) "text/plain; lang=en-US")

  ;; media-type
  (check-equal? (media-type 'plain) "text/plain")
  (check-equal? (media-type 'json) "application/json")
  (check-false (media-type 'invalid-thing)))

