#lang racket/base
;;
;; simple-oauth2 - oauth2/tools/fitbit.
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
         json
         oauth2
         oauth2/client
         oauth2/client/flow
         oauth2/storage/clients
         oauth2/storage/config
         oauth2/storage/tokens
         oauth2/tools/common)

;; ---------- Implementation

(define COMMAND "fitbit")

(define FITBIT-SERVICE-NAME "Fitbit API")

(define fitbit-client
  (make-client
   FITBIT-SERVICE-NAME
   #f
   #f
   "https://www.fitbit.com/oauth2/authorize"
   "https://api.fitbit.com/oauth2/token"
   #:revoke "https://api.fitbit.com/oauth2/revoke"
   #:introspect "https://api.fitbit.com/1.1/oauth2/introspect"))

(define logging-level (make-parameter 'warning))

(module+ main

  (define maybe-client (get-client FITBIT-SERVICE-NAME))

  (register-error-transformer (client-authorization-uri maybe-client) fitbit-error-handler)
  (register-error-transformer (client-token-uri maybe-client) fitbit-error-handler)
  
  (define thunk
    (cond
      [(or (false? maybe-client)
           (false? (client-id maybe-client)))
       (displayln "No client credentials stored, please authenticate.")
       (perform-authentication COMMAND maybe-client fitbit-client logging-level)]
      [(false? (get-token (get-current-user-name) FITBIT-SERVICE-NAME))
       (displayln "No authentication code stored, please authenticate.")
       (perform-authentication COMMAND maybe-client fitbit-client logging-level)]
      [else
       (log-oauth2-info "Authentication token already stored.")
       (perform-api-command maybe-client)]))

  (with-logging-to-port
      (current-output-port)
    thunk
    #:logger oauth2-logger
    (logging-level)))

;; ---------- Internal procedures

(define (fitbit-error-handler uri json-body cm)
  (cond
    [(hash-has-key? json-body 'errors)
     (define json-error (first (hash-ref json-body 'errors '())))
     (make-exn:fail:oauth2 (hash-ref json-error 'errorType 'unknown)
                           (hash-ref json-error 'message "")
                           uri
                           ""
                           cm)]
    [else #f]))

(define (parse-sleep json)
  (parse-rows json
              '(dateOfSleep startTime minutesToFallAsleep minutesAsleep minutesAwake
                            minutesAfterWakeup efficiency)
              'sleep
              '(deep:minutes deep:thirtyDayAvgMinutes deep:count
                             light:minutes light:thirtyDayAvgMinutes light:count
                             rem:minutes rem:thirtyDayAvgMinutes rem:count
                             wake:minutes wake:thirtyDayAvgMinutes wake:count)
              (λ (record keys)
                (cond
                  [(equal? (hash-ref record 'type) "stages")
                   (define summary (hash-ref (hash-ref record 'levels) 'summary))
                   (flatten
                    (for/list ([stage '(deep light rem wake)])
                      (define data (hash-ref summary stage))
                      (list (hash-ref data 'minutes)
                            (hash-ref data 'thirtyDayAvgMinutes)
                            (hash-ref data 'count))))]
                  [else
                   (make-list 12 0)]))))

(define (parse scope json)
  (cond
    [(equal? scope 'sleep)
     (parse-sleep json)]
    [(equal? scope 'weight)
     (parse-rows json '(date time weight bmi fat) 'weight)]))

(define (make-request-uri scope params)
  (cond
    [(equal? scope 'sleep)
     (format "https://api.fitbit.com/1.2/user/-/sleep/date/~a~a.json"
             (hash-ref params 'start-date)
             (if (hash-has-key? params 'end-date)
                 (string-append "/" (hash-ref params 'end-date))
                 ""))]
    [(equal? scope 'weight)
     (format "https://api.fitbit.com/1/user/-/body/log/weight/date/~a~a.json"
             (hash-ref params 'start-date)
             (if (hash-has-key? params 'end-date)
                 (string-append "/" (hash-ref params 'end-date))
                 ""))]))

(define (make-query-call scope params token)
  (define request-uri (make-request-uri scope params))
  (log-oauth2-info "Request URL <~a>" request-uri)
  (define locale-header
    (format "Accept-Language: ~a"
            (cond
              [(equal? (hash-ref params 'units) 'UK)
               "en_GB"]
              [(equal? (hash-ref params 'units) 'US)
               "en_US"]
              [else
               "en"])))
  (define response
    (resource-sendrecv
     request-uri
     token
     #:headers (list locale-header)))
  (cond
    [(= (first response) 200)
     (define data (parse scope (bytes->jsexpr (fourth response))))
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
     [("-u" "--units") units "Unit system (US, UK, metric)"
                          (hash-set! parameters 'units (string->symbol units))]
     [("-f" "--format") format "Output format (csv)"
                          (hash-set! parameters 'format (string->symbol format))]
     [("-o" "--output-file") path "Output file"
                             (hash-set! parameters 'output path)]
     #:args (scope)
     (if (set-member? (set "sleep" "weight") scope)
         (string->symbol scope)
         (error "unknown scope " scope))))
  
  (λ ()
    (define the-token (check-token-refresh client (get-current-user-name)))
    (make-query-call query-scope parameters the-token)))
