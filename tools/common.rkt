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
         racket/format
         racket/list
         racket/string
         oauth2
         oauth2/client/flow
         oauth2/storage/clients
         oauth2/storage/config
         oauth2/storage/tokens)

;; ---------- Implementation

(define (perform-authentication command maybe-client init-client logging-level)
  (define params (make-hash '((client-id . #f) (client-secret . #f) (auth-code . #f))))
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
     [("-i" "--client-id")
      id
      "Registered client ID"
      (hash-set! params 'client-id id)]
     [("-s" "--client-secret")
      secret
      "Registered client secret"
      (hash-set! params 'client-secret secret)]
     #:args (scope . scopes)
     (cons scope scopes)))

  (λ ()
    (cond
      [(or (false? (hash-ref params 'client-id))
           (false? (hash-ref params 'client-secret)))
       (displayln (format "~a: expects -i -s on the command line, try -h for help" command))]
      [else
       (define real-client
         (cond
           [(false? maybe-client)
            (struct-copy client init-client
                         [id (hash-ref params 'client-id)]
                         [secret (hash-ref params 'client-secret)])]
           [(false? (client-id maybe-client))
            (struct-copy client maybe-client
                         [id (hash-ref params 'client-id)]
                         [secret (hash-ref params 'client-secret)])]
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

(define hbar-single #\u2500)
(define vbar-single #\u2502)
(define top-left-single #\u250C)
(define top-right-single #\u2510)
(define bottom-right-single #\u2518)
(define bottom-left-single #\u2514)
(define left-tee-single #\u251C)
(define top-tee-single #\u252C)
(define right-tee-single #\u2524)
(define bottom-tee-single #\u2534)
(define cross-single #\u253C)

(define (display-data/screen data out [has-titles #t])
  (define widths (map (λ (c) (apply max (map string-length c))) (pivot data)))
  (display-screen-border 'top widths out)
  (define data-rows
    (cond
      [has-titles
       (display-screen-row (car data) widths out)
       (display-screen-border 'separator widths out)
       (cdr data)]
      [else data]))
  (for-each (λ (row) (display-screen-row row widths out)) data-rows)
  (display-screen-border 'bottom widths out))

(define (display-screen-border type widths out)
  (define fake-data (make-list (length widths) (string hbar-single)))
  (cond
    [(equal? type 'top)
     (display-screen-row fake-data widths out
                         #:pad (string hbar-single)
                         #:sep (string hbar-single top-tee-single hbar-single)
                         #:left top-left-single
                         #:right top-right-single)]
    [(equal? type 'separator)
     (display-screen-row fake-data widths out
                         #:pad (string hbar-single)
                         #:sep (string hbar-single cross-single hbar-single)
                         #:left left-tee-single
                         #:right right-tee-single)]
    [(equal? type 'bottom)
     (display-screen-row fake-data widths out
                         #:pad (string hbar-single)
                         #:sep (string hbar-single bottom-tee-single hbar-single)
                         #:left bottom-left-single
                         #:right bottom-right-single)]
    [else (error "unknown border type " type)]))

(define (display-screen-row row widths out
                            #:align [align 'left]
                            #:sep [sep (string #\space vbar-single #\space)]
                            #:pad [pad " "]
                            #:left [left vbar-single]
                            #:right [right vbar-single])
  (displayln
   (format "~a~a~a"
           left
           (string-join
            (for/list ([datum row] [width widths])
              (~a datum #:align align #:width width #:pad-string pad))
            sep)
           right)
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

