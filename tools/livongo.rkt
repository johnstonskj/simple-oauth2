#lang racket/base
;;
;; simple-oauth2 - oauth2/tools/livongo.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

;; ---------- Requirements

(require racket/bool
         racket/cmdline
         racket/date
         racket/format
         racket/list
         racket/logging
         racket/set
         racket/string
         json
         oauth2
         oauth2/client
         oauth2/client/flow
         oauth2/storage/clients
         oauth2/storage/config
         oauth2/storage/tokens
         oauth2/tools/common)

;; ---------- Implementation

(define COMMAND "livongo")

(define LIVONGO-SERVICE-NAME "Livongo BG API")

(define livongo-client
  (make-client
   LIVONGO-SERVICE-NAME
   "unknown"
   #f
   "https://mw.livongo.com/v1/users/me/auth"
   "https://mw.livongo.com/v1/users/me/auth"))

(define logging-level (make-parameter 'warning))

(module+ main

  (define maybe-client (get-client LIVONGO-SERVICE-NAME))

  (define thunk
    (cond
      [(false? maybe-client)
       (displayln "No client credentials stored, please authenticate.")
       (perform-password-authentication COMMAND livongo-client logging-level)]
      [(false? (get-token (get-current-user-name) LIVONGO-SERVICE-NAME))
       (displayln "No authentication code stored, please authenticate.")
       (perform-password-authentication COMMAND maybe-client logging-level)]
      [else
       (log-oauth2-info "Authentication token already stored.")
       (perform-api-command maybe-client)]))

  (with-logging-to-port
      (current-output-port)
    thunk
    #:logger oauth2-logger
    (logging-level)))

;; ---------- Internal procedures

(define (make-request-uri scope params)
  (cond
    [(equal? scope 'readings)
     (if (hash-has-key? params 'end-date)
         (format "https://mw.livongo.com/v1/users/me/readings/bgs?start=~a&end=~a&tagsIsControl=false"
             (hash-ref params 'start-date)
             (hash-ref params 'end-date))
         (format "https://mw.livongo.com/v1/users/me/readings/bgs?start=~a&tagsIsControl=false"
             (hash-ref params 'start-date)))]))

(define (make-query-call scope params token)
  (define request-uri (make-request-uri scope params))
  (log-oauth2-info "Request URL <~a>" request-uri)
  (define response
    (resource-sendrecv
     request-uri
     token))
  (cond
    [(= (first response) 200)
     (define data
       (parse-rows (bytes->jsexpr (fourth response))
                   '(storedTimestamp value)
                   'bgs))
     (display-data data (hash-ref params 'format) (hash-ref params 'output #f))]
    [else (error "HTTP error: " response)]))


(define (perform-api-command client)
  (date-display-format 'iso-8601)
  (define parameters (make-hash `((start-date . ,(date->string (current-date)))
                                  (units . US)
                                  (format . csv))))
  (define query-scope
    (command-line
     #:program COMMAND
     ;; ---------- Common commands
     #:once-any
     [("-v" "--verbose") "Compile with verbose messages"
                         (logging-level 'info)]
     [("-V" "--very-verbose") "Compile with very verbose messages"
                              (logging-level 'debug)]
     ;; ---------- API access commands
     #:once-each
     [("-s" "--start-date") start "Start date (YYYY-MM-DD)"
                            (hash-set! parameters 'start-date start)]
     [("-e" "--end-date") end "End date (YYYY-MM-DD)"
                          (hash-set! parameters 'end-date end)]
     [("-f" "--format") format "Output format (csv)"
                          (hash-set! parameters 'format (string->symbol format))]
     [("-o" "--output-file") path "Output file"
                             (hash-set! parameters 'output path)]
     #:args (scope)
     (if (set-member? (set "readings") scope)
         (string->symbol scope)
         (error "unknown scope " scope))))
  
  (λ ()
    (define the-token (check-token-refresh client (get-current-user-name)))
    (make-query-call query-scope parameters the-token)))
