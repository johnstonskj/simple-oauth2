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
         racket/format
         racket/list
         racket/logging
         racket/string
         json
         oauth2
         oauth2/client
         oauth2/client/flow
         oauth2/storage/clients
         oauth2/storage/config
         oauth2/storage/tokens)

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

(define c-client-id (make-parameter #f))
(define c-client-secret (make-parameter #f))
(define c-auth-code (make-parameter #f))
(define c-user (make-parameter (get-current-user-name)))
(define c-output-file (make-parameter #f))
(define logging-level (make-parameter 'warning))

(module+ main

  (define maybe-client (get-client FITBIT-SERVICE-NAME))

  (define thunk
    (cond
      [(or (false? maybe-client)
           (false? (client-id maybe-client)))
       (displayln "No client credentials stored, please authenticate.")
       (perform-authentication maybe-client)]
      [(false? (get-token (c-user) FITBIT-SERVICE-NAME))
       (displayln "No authentication code stored, please authenticate.")
       (perform-authentication maybe-client)]
      [else
       (log-oauth2-info "Authentication token already stored.")
       (perform-api-command maybe-client)]))

  (with-logging-to-port
      (current-output-port)
    thunk
    #:logger oauth2-logger
    (logging-level)))

;; ---------- Internal procedures

(define (perform-authentication maybe-client)
  (define c-scopes
    (command-line
     #:program COMMAND
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

  (λ ()
    (cond
      [(or (false? (c-user))
           (false? (c-client-id))
           (false? (c-client-secret)))
       (displayln "fitbit: expects -i -s on the command line, try -h for help")]
      [else
       (define real-client
         (cond
           [(false? maybe-client)
            (struct-copy client fitbit-client
                         [id (c-client-id)]
                         [secret (c-client-secret)])]
           [(false? (client-id maybe-client))
            (struct-copy client maybe-client
                         [id (c-client-id)]
                         [secret (c-client-secret)])]
           [else maybe-client]))
       (set-client! real-client)
       (save-clients)

       (with-handlers
           ([exn:fail:http?
             (lambda (exn)
               (displayln
                (format "An HTTP error occurred: ~a (~a)" 
                        (exn-message exn)
                        (exn:fail:http-code exn))))]
            [exn:fail:oauth2?
             (lambda (exn)
               (displayln exn)
               (display "An OAuth error occurred: ")
               (displayln (exn:fail:oauth2-error exn))
               (display ">>> ")
               (when (non-empty-string? (exn:fail:oauth2-error-description exn))
                 (displayln (exn:fail:oauth2-error-description exn)))
               (when (non-empty-string? (exn:fail:oauth2-error-uri exn))
                 (displayln (exn:fail:oauth2-error-uri exn))))])
         (define token
           (initiate-code-flow
            real-client
            c-scopes
            #:user-name (c-user)))

         (displayln (format "Fitbit returned authenication token: ~a" token)))])))

(define (parse-sleep json)
  (cons (map symbol->string
             '(date start minbefore minasleep minawake minafter
                    efficiency deep:min deep:avg deep:count light:min light:avg light:count
                    rem:min rem:avg rem:count wake:min wake:avg wake:count))
        (for/list ([record (hash-ref json 'sleep)])
          (map ~a
               (append (list (hash-ref record 'dateOfSleep)
                             (hash-ref record 'startTime))
                       (list (hash-ref record 'minutesToFallAsleep)
                             (hash-ref record 'minutesAsleep)
                             (hash-ref record 'minutesAwake)
                             (hash-ref record 'minutesAfterWakeup)
                             (hash-ref record 'efficiency))
                       (cond
                         [(equal? (hash-ref record 'type) "stages")
                          (define summary (hash-ref (hash-ref record 'levels) 'summary))
                          (flatten
                           (for/list ([stage '(deep light rem wake)])
                             (define data (hash-ref summary stage))
                             (list (hash-ref data 'minutes)
                                   (hash-ref data 'thirtyDayAvgMinutes)
                                   (hash-ref data 'count))))]))))))

(define (parse-weight json)
  (cons (map symbol->string
             '(date time weight bmi fat))
        (for/list ([record (hash-ref json 'weight)])
          (map ~a
               (list (hash-ref record 'date)
                     (hash-ref record 'time)
                     (hash-ref record 'weight)
                     (hash-ref record 'bmi)
                     (hash-ref record 'fat))))))

(define (parse scope json)
  (define csv-list
    (cond
      [(equal? scope 'sleep)
       (parse-sleep json)]
      [(equal? scope 'weight)
       (parse-weight json)]
      [else (error "unknown scope " scope)]))
  (for ([line csv-list])
    (displayln (string-join line ","))))

(define (make-query-call scope params token)
  (define request-uri
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
                   ""))]
      [else (error "Unknown scope: " scope)]))
  (log-oauth2-info "Request URL <~a>" request-uri)
  (define locale-header
    (format "Accept-Language: ~a"
            (cond
              [(equal? (hash-ref params 'units) "UK")
               "en_GB"]
              [(equal? (hash-ref params 'units) "US")
               "en_US"]
              [else
               "en"])))
  (define response (resource-sendrecv request-uri
                                      token
                                      #:headers (list locale-header)))
  (cond
    [(= (first response) 200)
     (parse scope (bytes->jsexpr (fourth response)))]
    [else (error "HTTP error: " response)]))


(define (perform-api-command client)
  (define parameters (make-hash '((start-date . "2019-01-22") (units . "US"))))
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
                          (hash-set! parameters 'units units)]
     [("-o" "--output-file") path "Output file"
                             (hash-set! parameters 'output path)]
     #:args (scope)
     (string->symbol scope)))
  
  (λ ()
    (define the-token (check-token-refresh client (get-current-user-name)))
    (make-query-call query-scope parameters the-token)))
