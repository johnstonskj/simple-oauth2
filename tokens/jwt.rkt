#lang racket/base
;;
;; simple-oauth2 - oauth2/tokens/jwt.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Support for parsing
;;   [JSON Web Token (JWT)](https://tools.ietf.org/html/rfc7519) values
;; this implies support for
;;   [JSON Web Signature (JWS)](https://tools.ietf.org/html/rfc7515),
;;   [JSON Web Encryption (JWE)](https://tools.ietf.org/html/rfc7516), and
;;   [JSON Web Algorithms (JWA)](https://tools.ietf.org/html/rfc7518).

(require racket/contract)

(provide
 (contract-out))

;; ---------- Requirements

(require)

;; ---------- Internal types

;; ---------- Implementation

;; ---------- Internal procedures

;; ---------- Internal tests

(module+ test
  (require rackunit)
  ;; only use for internal tests, use check- functions
  (check-true #f "dummy first test"))
