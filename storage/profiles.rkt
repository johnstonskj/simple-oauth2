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

(require racket/list
         oauth2/storage/config
         oauth2/private/logging
         oauth2/private/privacy
         oauth2/private/storage)

;; ---------- Internal types

;; ---------- Implementation

(define (create-default-profile)
  (get-current-user-name))

; (hash/c profile-name? (hash/c application-name? auth-code?))
(define-cached-file profiles 'home-dir ".oauth2.rkt")

(define (get-applications profile-name)
  (log-oauth2-debug "get-applications for ~a" profile-name)
  (filter
    (lambda (key) (equal? (first key) profile-name))
    (hash-keys profiles-cache)))

(define (get-auth-code profile-name app-name)
  (log-oauth2-debug "get-auth-code for ~a, ~a" profile-name app-name)
  (define key (cons profile-name app-name))
  (if (hash-has-key? profiles-cache key)
      ; decrypt
      (decrypt-secret (hash-ref profiles-cache key #f))
      #f))

(define (set-auth-code! profile-name app-name auth-code)
  (log-oauth2-debug "set-auth-code! for ~a, ~a" profile-name app-name)
  (define key (cons profile-name app-name))
  (hash-set! profiles-cache key (encrypt-secret auth-code)))

;; ---------- Startup procedures

(define loaded (load-profiles))
(log-oauth2-info "loading profiles: ~a" loaded)

(module+ test
  (require rackunit)
  ;; only use for internal tests, use check- functions
  (define starting-length (hash-count profiles-cache))
  (set-auth-code! "simonjo" "fitbit" #"9834rkjw34n3934-3fnfo")
  (check-equal? (hash-count profiles-cache) (+ starting-length 1))
  (check-equal? (get-auth-code "simonjo" "fitbit") #"9834rkjw34n3934-3fnfo")
  (check-false (get-applications "simonjoX"))
  (check-false (get-auth-code "simonjoX" "fitbit"))
  (check-false (get-auth-code "simonjo" "fitbitX")))
