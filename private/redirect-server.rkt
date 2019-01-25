#lang racket/base
;;
;; simple-oauth2 - oauth2/private/redirect-server.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide get-redirect-uri
         run-redirect-server
         redirect-server-uri
         shutdown-redirect-server
         record-auth-request)

;; ---------- Requirements

(require racket/bool
         racket/match
         racket/os
         web-server/servlet
         web-server/servlet-env
         oauth2/storage/config
         oauth2/private/external-ip
         oauth2/private/logging)

;; ---------- Implementation

(define (record-auth-request state)
  (define response-channel (make-channel))
  (channel-put request-channel (make-auth-request state response-channel))
  response-channel)

(define (get-redirect-uri)
  redirect-server-uri)

(define (run-redirect-server)
  (log-oauth2-info "run-redirect-server")
  (thread
    (lambda ()
      (log-oauth2-debug "run-redirect-server thread calling coordinator")
      (coordinator))))

(define (shutdown-redirect-server)
  (channel-put request-channel 'shutdown))

;; ---------- Internal Implementation

(define request-channel (make-channel))

(define-struct auth-request
  (state
   channel) #:transparent)

(define-struct auth-response
  (state
   code) #:transparent)

(define (coordinator)
  (log-oauth2-info "starting coordinator")
  (define http-thread
    (thread
      (lambda ()
        (cond 
          [(or (false? (server-config-ssl-certificate redirect-server))
               (false? (server-config-ssl-key redirect-server)))
            (log-oauth2-info "starting HTTP server")
            (serve/servlet 
              auth-response-servlet
              #:port (server-config-port redirect-server)
              #:servlet-path (server-config-path redirect-server)
              #:listen-ip #f
              #:launch-browser? #f
              #:log-file (current-output-port)
              #:log-format 'apache-default)]
          [else
            (log-oauth2-info "starting HTTPS server")
            (serve/servlet 
              auth-response-servlet
              #:port (server-config-port redirect-server)
              #:servlet-path (server-config-path redirect-server)
              #:listen-ip #f
              #:ssl-cert (server-config-ssl-certificate redirect-server)
              #:ssl-key (server-config-ssl-key redirect-server)
              #:launch-browser? #f
              #:log-file (current-output-port)
              #:log-format 'apache-default)]))))
  (log-oauth2-info "starting coordinator channel listener")
  (define requests (make-hash))
  (let next-request ([msg (channel-get request-channel)])
    (when (thread-dead? http-thread)
      (error "HTTP thread died, exiting coordinator"))
    (log-oauth2-debug "outstanding request count: ~a" (hash-count requests))
    (define continue
      (cond
        [(auth-request? msg)
          (log-oauth2-debug "recording auth request ~a" msg)
          (hash-set! requests (auth-request-state msg) (auth-request-channel msg))
          #t]
        [(auth-response? msg)
          (log-oauth2-debug "recording auth response ~a" msg)
          (define state (auth-response-state msg))
          (define response-channel (hash-ref requests state))
          (channel-put response-channel (auth-response-code msg))
          (hash-remove! requests state)
          #t]
        [(equal? msg 'shutdown)
          (log-oauth2-debug "recording showdown request!")
          ; inform any pending requests
          (hash-for-each
            requests
            (lambda (k v)
              (log-oauth2-debug "cancelling request, state: ~a" k)
              (channel-put v #f)))
          (kill-thread http-thread)
          #f]
        [else 
          (log-oauth2-error "unexpected message: ~a" msg)
          #t]))
    (when continue
      (next-request (channel-get request-channel)))))

; ?code=AUTH_CODE_HERE&state=1234zyx
(define (auth-response-servlet req)
;  (define path (path/param-path (car (url-path (request-uri req)))))
  (define params (make-hash (request-bindings req)))
  (cond
    [(and (hash-has-key? params 'state)
          (hash-has-key? params 'code))
      (define state (hash-ref params 'state))
      (define code (hash-ref params 'code))
      (channel-put request-channel (make-auth-response state code))
      (log-oauth2-info "received a code ~a for state ~a" code state)
      (response/full
        200 
        #"OK"
        (current-seconds) 
        TEXT/HTML-MIME-TYPE
        (list)
        (list #"<html><body><p>"
              #"Authenticated, code: "
              (string->bytes/utf-8 code)
              #"</p></body></html>"))]
    [(hash-has-key? params 'error)
      (log-oauth2-error "received ~a from auth server for state ~a" 
                        (hash-ref params 'error "")
                        (hash-ref params 'state ""))
      (channel-put request-channel (list 'error (hash-ref params 'error "")))
      (response/full
        200 
        #"OK-ish"
        (current-seconds) 
        TEXT/HTML-MIME-TYPE
        (list)
        (list #"<html><body><p>"
              #"Error"
              (hash-ref params 'error "")
              #" (state: "
              (hash-ref params 'state "")
              #")</br>"
              (hash-ref params 'error_description "")
              #"</br>"
              (hash-ref params 'error_uri "")
              #"</p></body></html>"))]
    [else
      (log-oauth2-error "received an unknown error from auth server: ~a" params)
      (channel-put request-channel '(error))
      (response/full
        500 
        #"SERVER ERROR"
        (current-seconds) 
        TEXT/HTML-MIME-TYPE
        (list)
        (list #"<html><body><p>"
              #"An error occurred :( "
              #"</p></body></html>"))]))

(define-struct server-config
  (host
   port
   path
   ssl-certificate
   ssl-key) #:transparent)

(define redirect-server
  (make-server-config
    (match (get-preference 'redirect-host-type)
          ['loopback "127.0.0.1"]
          ['localhost "localhost"]
          ['hostname (gethostname)]
          ['external (get-external-ip)])
    (get-preference 'redirect-host-port)
    (get-preference 'redirect-path)
    (get-preference 'redirect-ssl-certificate)
    (get-preference 'redirect-ssl-key)))

(define redirect-server-uri
  (format "http~a://~a:~a~a"
          (if (or (false? (server-config-ssl-certificate redirect-server))
                  (false? (server-config-ssl-key redirect-server))) "" "s")
          (server-config-host redirect-server) 
          (server-config-port redirect-server) 
          (server-config-path redirect-server)))
