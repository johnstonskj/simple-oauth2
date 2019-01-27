#lang racket/base
;;
;; simple-oauth2 - oauth2/client-flow.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide
  initiate-code-flow
  initiate-implicit-flow
  initiate-application-flow
  initiate-password-flow)

;; ---------- Requirements

(require oauth2/client
         oauth2/storage/clients
         oauth2/storage/profiles)

;; ---------- Implementation

(define (initiate-code-flow profile client scope #:state [state #f] #:challenge [challenge #f] #:audience [audience #f]) #f)

(define (initiate-implicit-flow) #f)

(define (initiate-application-flow) #f)

(define (initiate-password-flow) #f)
