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

(require
  (prefix-in c: oauth2/client))

;; ---------- Internal types

;; ---------- Implementation

(define openid-scope-id "openid")

(define (request-authorization-code client
                                    scopes
                                    #:state [state #f]
                                    #:challenge [challenge #f]
                                    #:audience [audience #f])
  (c:request-authorization-code client
                                (cons  openid-scope-id scopes)
                                #:state state
                                #:challenge challenge
                                #:audience audience))

;; ---------- Internal procedures

;; ---------- Internal tests


(module+ test
  (require rackunit)
  ;; only use for internal tests, use check- functions 
  (check-true #f "dummy first test"))

