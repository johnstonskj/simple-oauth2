#lang racket/base
;;
;; simple-oauth2 - oauth2.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide (except-out (struct-out client) make-client)
         (struct-out token)
         (rename-out [create-client make-client]))

;; ---------- Requirements

 (require net/url)

;; ---------- Implementation

; Note, we use #:prefab to allow these to be serialized using read/write.

(define-struct client
  (service-name
   authorization-uri
   token-uri
   revoke-uri
   introspect-uri
   id
   secret) #:prefab)

(define (create-client service-name id secret authorization-uri token-uri
                       #:revoke [revoke-uri #f] #:introspect [introspect-uri #f])
  (make-client service-name
               (string->url authorization-uri)
               (string->url token-uri)
               (if (string? revoke-uri)
                   (string->url revoke-uri)
                   #f)
               (if (string? introspect-uri)
                   (string->url introspect-uri)
                   #f)
               id
               secret))

(define-struct token
  (access-token
   type
   refresh-token
   audience
   scope
   expires) #:prefab)
