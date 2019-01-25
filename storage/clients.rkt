#lang racket/base
;;
;; simple-oauth2 - oauth2/storage/clients.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

(require racket/contract)

(provide
  get-client
  set-client!
  load-clients
  save-clients)

;; ---------- Requirements

(require racket/bool
         racket/file
         oauth2
         oauth2/private/logging
         oauth2/private/privacy
         oauth2/private/storage)

;; ---------- Implementation

; (hash/c application-name? (client?))
(define-cached-file clients 'home-dir ".oauth2.rkt")

(define (get-client app-name)
  (log-oauth2-debug "get-client for ~a" app-name)
  (define a-client (hash-ref clients-cache app-name #f))
  (if (false? a-client) 
    #f
    ; note, we only decrypt on access, not on load.
    (struct-copy client 
                 a-client 
                 [secret (decrypt-secret (client-secret a-client))])))

(define (set-client! app-name a-client)
  (log-oauth2-debug "set-client! ~a ~a" app-name (client-id a-client))
  ; note, we always encrypt into the cache, and therefore into save.
  (define new-client 
    (struct-copy client 
                 a-client
                 [secret (encrypt-secret (client-secret client))]))
  (hash-set! clients-cache app-name new-client))

;; ---------- Startup procedures

(define loaded (load-clients))
(log-oauth2-info "loading clients: ~a" loaded)

