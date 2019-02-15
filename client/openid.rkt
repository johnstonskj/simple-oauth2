#lang racket/base
;;
;; simple-oauth2 - oauth2/openid.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; OpenID Connect Core 1.0 incorporating errata set 1
;;   https://openid.net/specs/openid-connect-core-1_0.html

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

