#lang racket/base
;;
;; simple-oauth2 - oauth2/storage/profiles.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide
  create-default-profile
  get-applications
  get-auth-code
  set-auth-code!
  save-profiles
  load-profiles)

;; ---------- Requirements

(require oauth2/storage/config
         oauth2/private/logging
         oauth2/private/privacy
         oauth2/private/storage)

;; ---------- Internal types

;; ---------- Implementation

(define (create-default-profile)
  (get-current-user-name))

; (hash/c profile-name? (hash/c application-name? auth-code?))
(define-cached-file profiles 'home-dir ".oauth2.rkt")

(define (get-applications name)
  (log-oauth2-debug "get-applications for ~a" name)
  (hash-ref profiles-cache name #f))

(define (get-auth-code name app-name)
  (log-oauth2-debug "get-auth-code for ~a, ~a" name app-name)
  (displayln (format "get-auth-code for ~a, ~a" name app-name))
  (if (hash-has-key? profiles-cache name)
      ; decrypt
      (decrypt-secret (hash-ref (hash-ref profiles-cache name) app-name #f))
      #f))

(define (set-auth-code! name app-name auth-code)
  (log-oauth2-debug "set-auth-code! for ~a, ~a = ~a" name app-name auth-code)
  (unless (hash-has-key? profiles-cache name)
    (hash-set! profiles-cache name (make-hash)))
  (hash-set! (hash-ref profiles-cache name) app-name (encrypt-secret auth-code)))

;; ---------- Startup procedures

(define loaded (load-profiles))
(log-oauth2-info "loading profiles: ~a" loaded)

(module+ test
  (require rackunit)
  ;; only use for internal tests, use check- functions
  (define starting-length (hash-count profiles-cache))
  (set-auth-code! "simonjo" "fitbit" #"9834rkjw34n3934-3fnfo")
  (check-equal? (hash-count profiles-cache) (+ starting-length 1))
  (check-true (hash-has-key? (get-applications "simonjo") "fitbit"))
  (check-equal? (get-auth-code "simonjo" "fitbit") #"9834rkjw34n3934-3fnfo")
  (check-false (get-applications "simonjoX"))
  (check-false (get-auth-code "simonjoX" "fitbit"))
  (check-false (get-auth-code "simonjo" "fitbitX")))
