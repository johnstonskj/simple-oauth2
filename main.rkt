#lang racket/base
;;
;; simple-oauth2 - oauth2.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide (except-out (struct-out client) make-client)
         (rename-out [create-client make-client])
         (struct-out token)

         (struct-out exn:fail:http)
         make-exn:fail:http
         
         (struct-out exn:fail:oauth2)
         make-exn:fail:oauth2
         exn:fail:oauth2-error-description)

;; ---------- Requirements

(require racket/bool
         racket/string
         net/url)

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
  (unless (validate-url authorization-uri)
    (error "authorization URL is invalid: " authorization-uri))
  (unless (validate-url token-uri)
    (error "token URL is invalid: " token-uri))
  (unless (or (false? revoke-uri) (validate-url revoke-uri))
    (error "revoke URL is invalid: " revoke-uri))
  (unless (or (false? introspect-uri) (validate-url introspect-uri))
    (error "introspection URL is invalid: " introspect-uri))
  (make-client service-name
               authorization-uri
               token-uri
               (if (string? revoke-uri) revoke-uri #f)
               (if (string? introspect-uri) introspect-uri #f)
               id
               secret))

(define-struct token
  (access-token
   type
   refresh-token
   audience
   scopes
   expires) #:prefab)

(struct exn:fail:http exn:fail
  (code
   headers
   body) #:transparent)

(define (make-exn:fail:http code message headers body continuations)
  (exn:fail:http message continuations code headers body))

(struct exn:fail:oauth2 exn:fail
  (error
   error-uri
   state) #:transparent)

(define (make-exn:fail:oauth2 error error-description error-uri state continuations)
  (exn:fail:oauth2 error-description continuations error error-uri state))

(define (exn:fail:oauth2-error-description exn)
  (exn-message exn))

;; ---------- Internal Procedures

(define (validate-url url)
  (cond
    [(non-empty-string? url)
     (define parsed (string->url url))
     (and (and (string? (url-scheme parsed))
               (string-prefix? (url-scheme parsed) "http"))
          (non-empty-string? (url-host parsed))
          (url-path-absolute? parsed))]
    [else #f]))

;; ---------- Internal Tests

(module+ test
  (require rackunit)
  (check-true (validate-url "http://google.com"))
  (check-true (validate-url "http://google.com/q"))
  (check-true (validate-url "http://google.com/q"))
  (check-false (validate-url "ftp://google.com/q"))
  (check-false (validate-url "file:///q"))
  (check-false (validate-url "/path"))
  (check-false (validate-url "?query")))