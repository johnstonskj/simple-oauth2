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
         oauth2/client/flow
         oauth2/storage/clients
         oauth2/storage/tokens
         oauth2/private/redirect-server
         oauth2/private/logging)

;; ---------- Implementation

(define FITBIT "fitbit")
(define FITBIT-SERVICE-NAME "Fitbit API")
(define FITBIT-AUTH-URI "https://www.fitbit.com/oauth2/authorize")
(define FITBIT-TOKEN-URI "https://api.fitbit.com/oauth2/token")

(define c-client-id (make-parameter #f))
(define c-client-secret (make-parameter #f))
(define c-auth-code (make-parameter #f))
(define c-profile (make-parameter (create-default-user)))
(define c-output-file (make-parameter #f))
(define logging-level (make-parameter 'warning))

(module+ main

  (define maybe-client (get-client FITBIT-SERVICE-NAME))

  (define thunk
    (cond
      [(or (false? maybe-client)
           (false? (client-id maybe-client)))
       (displayln "No client credentials stored, please authenticate.")
       (λ () (perform-authentication maybe-client))]
      [(false? (get-token (c-profile) FITBIT-SERVICE-NAME))
        (displayln "No authentication code stored, please authenticate.")
        (λ () (perform-authentication maybe-client))]
      [else
       perform-api-command]))

  (with-logging-to-port
      (current-output-port)
    thunk
    #:logger oauth2-logger
    (logging-level)))

;; ---------- Internal procedures

(define (perform-authentication maybe-client)
  (define c-scopes
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
      [("-i" "--client-id") id "Registered client ID"
                            (c-client-id id)]
      [("-s" "--client-secret") secret "Registered client secret"
                                (c-client-secret secret)]
      #:args (scope . scopes)
      (cons scope scopes)))

  (cond
    [(or (false? (c-profile))
         (false? (c-client-id))
         (false? (c-client-secret)))
     (displayln "fitbit: expects -i -s on the command line, try -h for help")]
    [else
      (define real-client
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
      (set-client! FITBIT-SERVICE-NAME real-client)
      (save-clients)

      (define token
        (initiate-code-flow
          real-client
          c-scopes
          #:profile c-profile))

      (displayln (format "returned authenication token: ~a" token))]))

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
     [("-o" "--output-file") path "Output file"
                         (c-output-file path)]))
