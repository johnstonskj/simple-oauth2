#lang racket/base
;;
;; simple-oauth2 - oauth2/private/redirect-server.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide get-redirect-uri
         shutdown-redirect-server
         record-auth-request)

;; ---------- Requirements

(require racket/bool
         racket/match
         racket/os
         racket/string
         web-server/servlet
         web-server/servlet-env
         dali
         oauth2
         oauth2/storage/config
         oauth2/private/external-ip
         oauth2/private/http
         oauth2/private/logging)

;; ---------- Implementation

(define (record-auth-request state)
  (define response-channel (make-channel))
  (channel-put request-channel (make-auth-request state response-channel))
  response-channel)

(define (get-redirect-uri)
  redirect-server-uri)

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
  (define httpd-custodian (make-custodian))
  (parameterize ((current-custodian httpd-custodian))
    (thread http-server-thread))
  (log-oauth2-info "starting coordinator channel listener")
  (define requests (make-hash))
  (let next-request ([msg (channel-get request-channel)])
    (when (custodian-shut-down? httpd-custodian)
      (drain-request-channel requests)
      (error "HTTP thread shut down, exiting coordinator"))
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
         (drain-request-channel requests)
         (custodian-shutdown-all httpd-custodian)
         #f]
        [else
         (log-oauth2-error "unexpected message: ~a" msg)
         #t]))
    (when continue
      (next-request (channel-get request-channel)))))

(define (drain-request-channel requests)
  (hash-for-each
   requests
   (lambda (k v)
     (log-oauth2-debug "cancelling request, state: ~a" k)
     (channel-put v #f))))

(define (http-server-thread)
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
      #:log-format 'apache-default)]))

(define success-template
  (compile-string
   (string-append "<html>"
                  "<head><title>OAuth Authentication Result</title></head?"
                  "<body><h1>Authentication Succeeded</h1>"
                  "<p>Authentication code: {{code}} (for application state {{state}})</p>"
                  "<div hidden>"
                  "</div>"
                  "</body></html")))

(define failure-template
  (compile-string
   (string-append "<html>"
                  "<head><title>OAuth Authentication Result</title></head?"
                  "<body><h1>Authentication Failed/h1>"
                  "<p>Error: {{#code}}{{_}}{{/code}} {{#state}}"
                  "(for application state {{_}}){{/state}}"
                  "{{#error_description}}</br>{{_}}{{/error_description}}"
                  "{{#error_uri}}</br><a href=\"{{_}}\">More details.</a>{{/error_uri}}"
                  "</p>"
                  "<div hidden>"
                  "</div>"
                  "</body></html")))

(define error-template
  (compile-string
   (string-append "<html>"
                  "<head><title>OAuth Authentication Result</title></head?"
                  "<body><h1>Unknown Error</h1>"
                  "<p>No more information available</p>"
                  "<div hidden>"
                  "</div>"
                  "</body></html")))

(define (response-content template context)
  (define out (open-output-string))
  (template context out)
  (list (string->bytes/utf-8 (get-output-string out))))

(define response-type
  (make-media-type 'text 'html (hash 'charset 'utf-8)))

(define response-language
  (make-header-string 'content-language "en"))

(define response-no-cache
  (make-header-string 'cache-control (make-header-options '(no-cache no-store must-revalidate))))
   
(define (auth-response-servlet req)
  (define params (make-hash (request-bindings req)))
  (cond
    [(and (hash-has-key? params 'state)
          (hash-has-key? params 'code))
     (define state (hash-ref params 'state))
     (define code (hash-ref params 'code))
     (channel-put request-channel (make-auth-response state code))
     (log-oauth2-info "received an authentication code ~a, for state ~a" code state)
     (response/full
      (error-code 'ok)
      (error-message/bytes 'ok)
      (current-seconds)
      response-type
      (list response-language response-no-cache)
      (response-content success-template params))]
    [(hash-has-key? params 'error)
     (log-oauth2-error "received error ~a from auth server, for state ~a"
                       (hash-ref params 'error)
                       (hash-ref params 'state ""))
     (channel-put request-channel
                  (make-exn:fail:oauth2 (hash-ref params 'error)
                                        (hash-ref params 'error_description "")
                                        (hash-ref params 'error_uri)
                                        (hash-ref params 'state)
                                        (current-continuation-marks)))
     (response/full
      (error-code 'ok)
      (error-message/bytes 'ok)
      (current-seconds)
      response-type
      (list response-language response-no-cache)
      (response-content failure-template params))]
    [else
     (log-oauth2-error "received an unknown error from auth server: ~a" params)
     (channel-put request-channel
                  (make-exn:fail:http 'server-error
                                      'server-error
                                      params
                                      ""
                                      (current-continuation-marks)))
     (response/full
      (error-code 'server-error)
      (error-message/bytes 'server-error)
      (current-seconds)
      response-type
      (list response-language response-no-cache)
      (response-content error-template params))]))

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

(define (run-redirect-coordinator)
  (log-oauth2-info "run-redirect-coordinator")
  (thread
   (lambda ()
     (log-oauth2-debug "run-redirect-coordinator thread calling coordinator")
     (coordinator))))

(void (run-redirect-coordinator))
