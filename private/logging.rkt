#lang racket/base
;;
;; simple-oauth2 - oauth2/private/logging.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide
 
 (all-defined-out))

;; ---------- Requirements

(require racket/logging)

;; ---------- Implementation

(define-logger oauth2)

(current-logger oauth2-logger)
