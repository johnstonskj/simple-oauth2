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

(define deps '(
  "base"
  "web-server-lib"
  "crypto-lib"
  "rackunit-lib"
  "racket-index"))
(define build-deps '(
  "scribble-lib"
  "racket-doc"
  "sandbox-lib"
  "cover-coveralls"))

(define scribblings '(("scribblings/simple-oauth2.scrbl" (multi-page))))

(define test-omit-paths '("scribblings" "private"))

(define racket-launcher-names '("fitbit"))
(define racket-launcher-libraries '("tools/fitbit.rkt"))
