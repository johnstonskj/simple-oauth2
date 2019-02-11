#lang racket/base
;;
;; simple-oauth2 - oauth2.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require oauth2/private/logging)

(provide OAUTH-SPEC-VERSION
         OAUTH-RFC
         OAUTH-DISPLAY-NAME
         
         (except-out (struct-out client) make-client)
         (rename-out [create-client make-client])
         
         (struct-out token)

         (struct-out exn:fail:http)
         make-exn:fail:http
         
         (struct-out exn:fail:oauth2)
         make-exn:fail:oauth2
         exn:fail:oauth2-error-description

         (all-from-out oauth2/private/logging))

;; ---------- Requirements

(require racket/bool
         racket/string
         net/url
         oauth2/private/http)

;; ---------- Implementation

(define OAUTH-SPEC-VERSION 2.0)

(define OAUTH-RFC 6749)

(define OAUTH-DISPLAY-NAME (format "RFC~a: OAuth ~a (https://tools.ietf.org/html/rfc~a)"
                                   OAUTH-RFC OAUTH-SPEC-VERSION OAUTH-RFC))

;; Useful to put this into the log nice and early.
(log-oauth2-info "simple-oauth2 package, implementing ~a." OAUTH-DISPLAY-NAME)

(define-struct client
  ;; Using #:prefab to allow these to be serialized using read/write.
  (service-name
   authorization-uri
   token-uri
   revoke-uri
   introspect-uri
   id
   secret) #:prefab)

(define (create-client service-name id secret authorization-uri token-uri
                       #:revoke [revoke-uri #f] #:introspect [introspect-uri #f])
  (unless (non-empty-string? service-name)
    (error "service name must be a non-empty string"))
  (unless (non-empty-string? id)
    (error "client id must be a non-empty string"))
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
  (exn:fail:http
   (if (symbol? message) (error-message message) message)
   continuations
   (if (symbol? code) (error-code code) code)
   headers
   body))

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

  (define valid-url "http://google.com")
  (define not-valid-url "this is not a url, honestly")
  
  ;; create-client
  (check-true (client? (create-client "service name" "id" "secret" valid-url valid-url)))
  (check-exn exn:fail? (λ () (create-client "" "id" "secret" valid-url valid-url)))
  (check-exn exn:fail? (λ () (create-client "service name" "" "secret" valid-url valid-url)))
  (check-exn exn:fail? (λ () (create-client "service name" "id" "secret" not-valid-url valid-url)))
  (check-exn exn:fail? (λ () (create-client "service name" "id" "secret" valid-url not-valid-url)))
  (check-exn exn:fail? (λ () (create-client "service name" "id" "secret" valid-url valid-url #:revoke not-valid-url)))
  (check-exn exn:fail? (λ () (create-client "service name" "id" "secret" valid-url valid-url #:introspect not-valid-url)))
    
  ;; validate-url
  (check-true (validate-url valid-url))
  (check-true (validate-url "http://google.com/q"))
  (check-true (validate-url "http://google.com/q"))
  (check-false (validate-url "ftp://google.com/q"))
  (check-false (validate-url not-valid-url))
  (check-false (validate-url "file:///q"))
  (check-false (validate-url "/path"))
  (check-false (validate-url "?query")))