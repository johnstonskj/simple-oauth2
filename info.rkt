#lang info
;;
;; Package simple-oauth2.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(define collection "oauth2")

(define pkg-desc "Simple OAuth2 client and server implementation")
(define version "0.1")
(define pkg-authors '(Simon Johnston))

(define deps
  '("base"
    ;; add-on libraries
    "crypto-lib"
    "dali"
    "net-jwt"
    "threading"
    "web-server-lib"
    ;; testing
    "rackunit-lib"
    "rackunit-spec"))
(define build-deps
  '(;; documentation
    "scribble-lib"
    "racket-doc"
    "racket-index"
    "sandbox-lib"
    ;; coverage (Travis)
    "cover-coveralls"))

(define scribblings
  '(("scribblings/simple-oauth2.scrbl" (multi-page))))

(define test-omit-paths
  '("scribblings"))

(define racket-launcher-names
  '("fitbit" "livongo"))
(define racket-launcher-libraries
  '("tools/fitbit.rkt" "tools/livongo.rkt"))
