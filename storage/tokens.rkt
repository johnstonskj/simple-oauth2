#lang racket/base
;;
;; simple-oauth2 - oauth2/storage/tokens.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide get-services-for-user
         get-token
         set-token!
         save-tokens
         load-tokens)

;; ---------- Requirements

(require racket/list
         oauth2
         oauth2/storage/config
         oauth2/private/logging
         oauth2/private/privacy
         oauth2/private/storage)

;; ---------- Internal types

;; ---------- Implementation

; (hash/c token-name? (hash/c application-name? auth-code?))
(define-cached-file tokens 'home-dir ".oauth2.rkt")

(define (get-services-for-user user-name)
  (log-oauth2-debug "get-services for ~a" user-name)
  (filter
   (lambda (key) (equal? (first key) user-name))
   (hash-keys tokens-cache)))

(define (get-token user-name service-name)
  (log-oauth2-debug "get-token for ~a, ~a" user-name service-name)
  (define key (cons user-name service-name))
  (cond
    [(hash-has-key? tokens-cache key)
     (define a-token (hash-ref tokens-cache key))
     (struct-copy token
                  a-token
                  [access-token (decrypt-secret (token-access-token a-token))]
                  [refresh-token (decrypt-secret (token-refresh-token a-token))]
                  [expires (if (> (current-seconds) (token-expires a-token))
                               -1
                               (token-expires a-token))])]
    [else #f]))

(define (set-token! user-name service-name a-token)
  (log-oauth2-debug "set-token! for ~a (~a), ~a ~a"
                    user-name
                    (string? user-name)
                    service-name
                    (token-refresh-token a-token)
                    )
  (define key (cons user-name service-name))
  (hash-set! tokens-cache
             key
             (struct-copy token
                          a-token
                          [access-token (encrypt-secret (token-access-token a-token))]
                          [refresh-token
                            (if (token-refresh-token a-token)
                                (encrypt-secret (token-refresh-token a-token))
                                #f)
                                ])))

;; ---------- Startup procedures

(define loaded (load-tokens))
(log-oauth2-info "loading tokens: ~a" loaded)
