#lang racket/base
;;
;; simple-oauth2 - oauth2/storage/config.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide get-current-user-name
         get-current-user-name/bytes
         get-preference
         set-preference!
         (rename-out [load-or-create-preferences load-preferences])
         save-preferences)

;; ---------- Requirements

(require racket/bool
         racket/file
         racket/port
         crypto
         crypto/libcrypto
         oauth2
         oauth2/private/logging
         oauth2/private/storage)

;; ---------- Implementation

(define (get-current-user-name)
  (bytes->string/utf-8 (get-current-user-name/bytes)))

(define (get-current-user-name/bytes)
  (environment-variables-ref 
   (current-environment-variables) 
   #"USER"))

; (hash/c symbol? any/c)
(define-cached-file preferences 'home-dir ".oauth2.rkt")

(define (get-preference name)
  (log-oauth2-debug "get-preference for ~a" name)
  (hash-ref preferences-cache name #f))

(define (set-preference! name value)
  (log-oauth2-debug "set-preference! ~a ~a" name value)
  (hash-set! preferences-cache name value))

(define (load-or-create-preferences)
  (define path (get-preferences-file-path))
  (cond 
    [(false? (file-exists? path))
     (log-oauth2-info "creating new config file in ~a" path)
     (crypto-factories (list libcrypto-factory))
     (define cipher-impl '(aes gcm))
     (set-preference! 'cipher-impl cipher-impl)
     (set-preference! 'cipher-key (generate-cipher-key cipher-impl))
     (set-preference! 'cipher-iv (generate-cipher-iv cipher-impl))
     (set-preference! 'redirect-host-type 'localhost)
     (set-preference! 'redirect-host-port 8080)
     (set-preference! 'redirect-path "/oauth/authorization")
     (set-preference! 'redirect-ssl-certificate #f)
     (set-preference! 'redirect-ssl-key #f)
     (save-preferences)]
    [else
     (load-preferences)]))

;; ---------- Startup procedures

(define loaded (load-or-create-preferences))

