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
  
(define (header-name sym)
  (cond
    [(set-member? (set 'authorization 'content-language 'content-type) sym)
     (string-titlecase (symbol->string sym))]
    [else #f]))

(define (make-header-parameter sym value)
  (format "; ~a=~a" sym value))

(define (make-header-parameters parameter-hash)
  (string-join
   (hash-map parameter-hash (λ (k v) (make-header-parameter k v)))
   ""))

(define (make-header-string sym value [parameters (hash)])
  (format "~a: ~a~a"
          (header-name sym)
          value
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
