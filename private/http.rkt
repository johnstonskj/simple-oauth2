#lang racket/base
;;
;; simple-oauth2 - private/http.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide (all-defined-out))

;; ---------- Requirements

(require racket/string)

;; ---------- Implementation

(define (header-name sym)
  (cond
    [(equal? sym 'authorization) "Authorization"]
    [(equal? sym 'content-type) "Content-Type"]
    [else #f]))

(define (make-header-parameter sym value)
  (format "; ~a=~a" sym value))

(define (make-header-string sym value [parameters (hash)])
  (format "~a: ~a~a"
          (header-name sym)
          value
          (string-join
           (hash-map parameters (λ (k v) (make-header-parameter k v)))
           "")))

(define (media-type sym)
  (cond
    [(equal? sym 'html) "text/html"]
    [(equal? sym 'json) "application/json"]
    [(equal? sym 'form-urlencoded) "application/x-www-form-urlencoded"]
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
