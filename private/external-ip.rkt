#lang racket/base
;;
;; simple-oauth2 - oauth2/private/external-ip.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide get-external-ip)

;; ---------- Requirements

(require racket/bool
         racket/list
         racket/port
         openssl
         net/http-client)


;; ---------- Internal values

(define *cached-ip* #f)

(define external-ip-servers
  '(("ipecho.net" "/plain" auto)
    ("checkip.amazonaws.com" "/" #f)))

;; ---------- Implementation

(define (get-external-ip)
  (when (false? *cached-ip*)
    (define include-server
      (cond 
        [ssl-available?
         (λ (s) #t)]
        [else
         (λ (s) (false? (third s)))]))
    (for/or ([server (filter include-server external-ip-servers)])
      (set! *cached-ip* (try-external-ip server))
      *cached-ip*))
  *cached-ip*)

;; ---------- Internal procedures

(define (try-external-ip server)
  (define-values 
    (status headers in-port)
    (http-sendrecv
     (first server)
     (second server)
     #:ssl? (third server)))
  (port->string in-port))
