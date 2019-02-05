#lang racket/base
;;
;; simple-oauth2 - oauth2/tools/common.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide
 perform-authentication
 display-data)

;; ---------- Requirements

(require racket/bool
         racket/cmdline
         racket/date
         racket/format
         racket/list
         racket/logging
         racket/string
         oauth2
         oauth2/client
         oauth2/client/flow
         oauth2/storage/clients
         oauth2/storage/config
         oauth2/storage/tokens)

;; ---------- Implementation

(define c-client-id (make-parameter #f))
(define c-client-secret (make-parameter #f))
(define c-auth-code (make-parameter #f))
(define c-output-file (make-parameter #f))

(define (perform-authentication command maybe-client init-client logging-level)
  (define c-scopes
    (command-line
     #:program command
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
      [(or (false? (c-client-id))
           (false? (c-client-secret)))
       (displayln (format "~a: expects -i -s on the command line, try -h for help" command))]
      [else
       (define real-client
         (cond
           [(false? maybe-client)
            (struct-copy client init-client
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
            #:user-name (get-current-user-name)))

         (displayln (format "Service returned authenication token: ~a" token)))])))

(define (display-data data format output-to)
  (define (display-with-port out)
    (cond
      [(equal? format 'csv)
       (display-data/csv data out)]
      [(equal? format 'screen)
       (display-data/screen data out)]
      [else (error "unknown format " format)]))
  (cond
    [(false? output-to)
     (display-with-port (current-output-port))]
    [(path-string? output-to)
     (call-with-output-file output-to display-with-port)]
    [else (error "invalid file path " output-to)]))

;; ---------- Internal procedures

(define (display-data/screen data out [has-titles #t])
  (define widths (map (λ (c) (apply max (map string-length c))) (pivot data)))
  (define data-rows
    (cond
      [has-titles
       (display-screen-row (car data) widths out)
       (display-screen-row (make-list (length widths) "-") widths out #:sep "-+-" #:pad "-")
       (cdr data)]
      [else data]))
  (for-each (λ (row) (display-screen-row row widths out)) data-rows))

(define (display-screen-row row widths out #:sep [sep " | "] #:pad [pad " "])
  (displayln
   (string-join
    (for/list ([datum row] [width widths])
      (~a datum #:width width #:pad-string pad))
    sep)
   out))

(define (pivot tabular)
  ;; this is not meant for speed, it also doesn't do size checks.
  (cons
   (for/list ([row tabular])
     (car row))
   (if (equal? (cdr (car tabular)) '())
       '()
       (pivot (for/list ([row tabular])
                (cdr row))))))

(define (display-data/csv data out)
  (for-each (λ (line) (displayln (string-join line ",") out)) data))

