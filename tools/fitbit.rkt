#lang racket/base
;;
;; simple-oauth2 - simple-oauth2.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; Racket Style Guide: http://docs.racket-lang.org/style/index.html

;; ---------- Requirements

(require racket/bool
         racket/cmdline
         racket/logging
         oauth2
         oauth2/client
         oauth2/storage/clients
         oauth2/storage/profiles
         oauth2/private/redirect-server
         oauth2/private/logging)

;; ---------- Implementation

(define c-client-id (make-parameter ""))
(define c-client-secret (make-parameter ""))
(define c-scopes (make-parameter '()))
(define c-auth-code (make-parameter ""))
(define c-profile (make-parameter (create-default-profile)))
(define c-output-file (make-parameter "."))
(define logging-level (make-parameter 'warning))

(module+ main

  (define maybe-client (get-client "Fitbit API"))

  (define thunk
    (cond
      [(or (false? maybe-client)
           (false? (client-id maybe-client)))
       (displayln "No client credentials stored, please authenticate.")
       (λ () (perform-authentication maybe-client))]
      [else
       perform-api-command]))

  (with-logging-to-port
      (current-output-port)
    thunk
    #:logger oauth2-logger
    (logging-level)))

;; ---------- Internal types

(define FITBIT "fitbit")
(define FITBIT-SERVICE-NAME "Fitbit API")
(define FITBIT-AUTH-URI "https://www.fitbit.com/oauth2/authorize")
(define FITBIT-TOKEN-URI "https://api.fitbit.com/oauth2/token")

;; ---------- Internal procedures

(define (perform-authentication maybe-client)
  (command-line
    #:program FITBIT
    ;; ---------- Common commands
    #:once-any
    [("-v" "--verbose")
           "Compile with verbose messages"
           (logging-level 'info)]
    [("-V" "--very-verbose")
           "Compile with very verbose messages"
           (logging-level 'debug)]
    ;; ---------- Authentication flow
    #:once-each
    [("-p" "--profile")
           profile
           "Client Profile to save"
           (c-profile profile)]
    [("-i" "--client-id") id "Registered client ID"
                          (c-client-id id)]
    [("-s" "--client-secret") secret "Registered client secret"
                              (c-client-secret secret)]
    #:multi
    [("-S" "--scopes") scope "Authorize scope"
                       (c-scopes (cons scope (c-scopes)))])
  (set-client! FITBIT-SERVICE-NAME
   (cond
     [(false? maybe-client)
      (make-client
        FITBIT-SERVICE-NAME
        (c-client-id)
        (c-client-secret)
        FITBIT-AUTH-URI
        FITBIT-TOKEN-URI)]
     [(false? (client-id maybe-client))
      (struct-copy client maybe-client
        [id (c-client-id)]
        [secret (c-client-secret)])]))
  (save-clients))

(define (perform-api-command)
  (command-line
     #:program FITBIT
     ;; ---------- Common commands
     #:once-any
     [("-v" "--verbose") "Compile with verbose messages"
                         (logging-level 'info)]
     [("-V" "--very-verbose") "Compile with very verbose messages"
                         (logging-level 'debug)]
     ;; ---------- API access commands
     #:once-each
     [("-p" "--profile") profile "Client Profile"
                         (c-profile profile)]
     [("-c" "--auth-code") id "Authentication code"
                         (client-id id)]
     [("-o" "--output-file") path "Output file"
                         (c-output-file path)]))
