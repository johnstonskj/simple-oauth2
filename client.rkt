#lang racket/base
;;
;; simple-oauth2 - oauth2/client.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).
;;
;; This implementation references the following specifications:
;;
;; * The OAuth 2.0 Authorization Framework <https://tools.ietf.org/html/rfc6749>
;; * Proof Key for Code Exchange (PKCE) by OAuth Public Clients <https://tools.ietf.org/html/rfc7636>
;; * OAuth 2.0 Token Revocation <https://tools.ietf.org/html/rfc7009>
;; * OAuth 2.0 Token Introspection <https://tools.ietf.org/html/rfc7662>

(provide create-random-state
         
         request-authorization-code
         authorization-complete
         
         grant-token/from-authorization-code
         grant-token/implicit
         grant-token/from-owner-credentials
         grant-token/from-client-credentials
         grant-token/extension
         
         refresh-token
         revoke-token
         introspect-token

         register-error-transformer
         deregister-error-transformer
         
         make-authorization-header
         resource-sendrecv

         oauth-namespace-urn
         oauth-grant-type-urn)

;; ---------- Requirements

(require racket/bool
         racket/lazy-require
         racket/list
         racket/match
         racket/port
         racket/random
         racket/string
         racket/system
         file/sha1
         json
         net/base64
         net/jwt/base64
         net/http-client
         net/uri-codec
         net/url
         net/url-string
         oauth2
         oauth2/client/pkce
         oauth2/private/http
         oauth2/private/logging
         oauth2/private/privacy)

(lazy-require
 [oauth2/private/redirect-server
  (get-redirect-uri
   record-auth-request
   shutdown-redirect-server)])

;; ---------- Implementation - Extensions
;; ;; see https://tools.ietf.org/html/rfc6755

(define oauth-namespace-urn "urn:ietf:params:oauth:")

(define oauth-grant-type-urn "urn:ietf:params:oauth:grant-type:")

;; ---------- Implementation - Grants

(define error-transformers (make-hash))

(define (register-error-transformer url func)
  (hash-set! error-transformers url func))

(define (deregister-error-transformer url)
  (hash-remove! error-transformers url))

(define (create-random-state [bytes 16])
  (unless (and (exact-nonnegative-integer? bytes) (> bytes 8) (< bytes 128))
    (error 'create-random-state "not a valid value for number of bytes: " bytes))
  (bytes->hex-string (crypto-random-bytes bytes)))

(define (request-authorization-code
         client scopes #:state [state #f] #:challenge [challenge #f] #:audience [audience #f])
  (log-oauth2-info "request-authorization-code from ~a" (client-service-name client))
  (define use-state (if (false? state) (create-random-state) state))
  (define query (append `((response_type . "code")
                          (client_id . ,(client-id client))
                          (redirect_uri . ,(get-redirect-uri))
                          (scope . ,(string-join scopes " "))
                          (state . ,use-state))
                        (if (false? audience)
                            '()
                            `((audience . ,audience)))
                        (if (false? challenge)
                            '()
                            `((code_challenge . ,(pkce-challenge challenge))
                              (code_challenge_method . ,(pkce-method challenge))))))
  (define query-string (alist->form-urlencoded query))
  (define full-url
    (url->string
     (combine-url/relative
      (string->url (client-authorization-uri client))
      (string-append "?" query-string))))
  (parameterize ([current-error-port (open-output-string "stderr")])
    (define cmd (format (match (system-type 'os)
                          ['windows "cmd /c start \"~a\""]
                          ['macosx "open \"~a\""]
                          ['unix "xdg-open \"~a\""])
                        full-url))
    (log-oauth2-debug "starting browser: ~a" cmd)
    (define success? (system cmd))
    (cond
      [success?
       ; return the response channel
       (record-auth-request use-state)]
      [else
       (define error-string (get-output-string (current-error-port)))
       (log-oauth2-error "system call failed. error: ~a" error-string)
       (error "system call failed. error: " error-string)])))

(define (authorization-complete)
  (shutdown-redirect-server))

(define (grant-token/from-authorization-code client authorization-code #:challenge [challenge #f])
  (log-oauth2-info "grant-token/from-authorization-code, service ~a, code ~a"
                   (client-service-name client) authorization-code)
  (token-request-common
   client
   (append `((grant_type . "authorization_code")
             (code . ,authorization-code)
             (redirect_uri . ,(get-redirect-uri))
             (client_id . ,(client-id client)))
           (if (false? challenge)
               '()
               `((code_verifier . ,(pkce-verifier challenge)))))))

(define (grant-token/implicit client scopes #:state [state #f] #:audience [audience #f])
  #f)

(define (grant-token/from-owner-credentials client username password)
  (log-oauth2-info "grant-token/from-owner-credentials, service ~a, username ~a"
                   (client-service-name client) username)
  (token-request-common
   client
   `((grant_type . "password")
     (username . ,username)
     (password . ,password)
     (client_id . ,(client-id client)))))

(define (grant-token/from-client-credentials client)
  (log-oauth2-info "grant-token/from-client-credentials, service ~a, client ~a"
                   (client-service-name client)
                   (client-id client))
  (token-request-common
   client
   `((grant_type . "password")
     (client_id . ,(client-id client))
     (client_secret . ,(client-secret client)))))

(define (grant-token/extension client grant-type-urn [parameters (hash)])
  (log-oauth2-info "grant-token/extension, service ~a, grant type ~a"
                   (client-service-name client)
                   grant-type-urn)
  (unless (string-prefix? grant-type-urn oauth-grant-type-urn)
    (error "invalid extension URN " grant-type-urn))
  (token-request-common
   client
   '((grant_type . ,grant-type-urn)
     (hash-map parameters (λ (k v) (cons k v))))))

;; ---------- Implementation - Token Management

(define (refresh-token client token)
  (log-oauth2-info "refresh-token, service ~a" (client-service-name client))
  (token-request-common
   client
   `((grant_type . "refresh_token")
     (refresh_token . ,(token-refresh-token token))
     (client_id . ,(client-id client))
     (client_secret . ,(client-secret client)))))

(define (revoke-token client token token-type-hint)
  (log-oauth2-info "revoke-token, service ~a" (client-service-name client))
  (token-request-common
   client
   `((token_type_hint . ,(string-replace (symbol->string token-type-hint)))
     (token . ,(get-token token token-type-hint)))))

(define (introspect-token client token token-type-hint)
  (log-oauth2-info "introspect-token, service ~a" (client-service-name client))
  (token-request-common
   client
   `((token_type_hint . ,(string-replace (symbol->string token-type-hint)))
     (token . ,(get-token token token-type-hint)))))

;; ---------- Implementation - Resource Access

(define (make-authorization-header token)
  (string->bytes/utf-8 (format "~a: ~a ~a"
                               (header-name 'authorization)
                               (token-type token)
                               (token-access-token token))))

(define (resource-sendrecv resource-uri token #:method [method "GET"] #:headers [headers '()] #:data [data #f])
  (define uri (string->url resource-uri))
  (define-values
    (status response-headers in-port)
    (http-sendrecv
     (url-host uri)
     resource-uri
     #:ssl? (equal? (url-scheme uri) "https")
     #:method method
     #:headers (cons (make-authorization-header token) headers)
     #:data data))
  (log-oauth2-debug "(values ~s ~s #port)" status response-headers)
  (parse-response status response-headers in-port))

;; ---------- Internal Implementation

(define empty-string "")

(define (get-token token type)
  (cond
    [(equal? type 'access-token)  (token-access-token token)]
    [(equal? type 'refresh-token) (token-refresh-token token)]
    [else (error "unknown token type: " type)]))

(define (token-request-common client data-list)
  (define headers
    (cons
      (make-header-string 'accept "application/json")
      (if (false? (client-secret client))
          '()
          ;; RFC6749 §2.3
          (list (make-auth-header (string-trim (bytes->string/latin-1 (encode-client client)))))))
  )
  (define response
    (do-post/form-encoded-list/json
     (string->url (client-token-uri client))
     headers
     data-list))
  (cond
    [(= (first response) (error-code 'ok))
     (token-from-response (last response))]
    [else
     (response)]))

(define (do-post/form-encoded-list/json uri headers data-list)
  (define response
    (do-post
     uri
     headers
     (alist->form-urlencoded data-list)
     (media-type 'form-urlencoded)))
  (list-update response 3 bytes->jsexpr))

(define (do-post/form-encoded-list uri headers data-list)
  (do-post
   uri
   headers
   (alist->form-urlencoded data-list)
   (media-type 'form-urlencoded)))

(define (do-post uri request-headers data data-type)
  (log-oauth2-debug "(http-sendrecv")
  (log-oauth2-debug "  ~s" (url-host uri))
  (log-oauth2-debug "  ~s" uri)
  (log-oauth2-debug "  #:port ~s" (url-port uri))
  (log-oauth2-debug "  #:ssl? ~s ; ~s" (equal? (url-scheme uri) "https") (url-scheme uri))
  (log-oauth2-debug "  #:headers ~s" (cons (make-header-string 'content-type data-type) request-headers))
  (log-oauth2-debug "  #:data ~s)" data)
  (define-values
    (status response-headers in-port)
    (http-sendrecv
     (url-host uri)
     (url->string uri)
     ;      #:port (false? (url-port uri)
     #:ssl? (equal? (url-scheme uri) "https")
     #:method "POST"
     #:headers (cons (format "~a: ~a" (header-name 'content-type) data-type) request-headers)
     #:data data))
  (log-oauth2-debug "(values ~s ~s #port)" status response-headers)
  (parse-response/with-errors uri status response-headers in-port))

(define (string-split-first str sep)
  (define index
    (for/or ([char (string->list str)] [i (range (string-length str))])
      (if (equal? char sep) i #f)))
  (if (false? index)
      (values str empty-string)
      (values (substring str 0 index) (string-trim (substring str index)))))

(define (parse-response/with-errors uri status headers in-port)
  (define response (parse-response status headers in-port))
  (when (<= (error-code 'bad-request) (first response) (error-code 'last-error))
    (log-oauth2-error "error response, code ~a, body ~a" (first response) (fourth response))
    (define content-type (hash-ref (third response) (header-name 'content-type)))
    (cond
      [(string-prefix? content-type (media-type 'json))
       (define json-body (bytes->jsexpr (fourth response)))
       (cond
         [(hash-has-key? json-body 'error)
          (raise (make-exn:fail:oauth2 (hash-ref json-body 'error 'unknown)
                                       (hash-ref json-body 'error_description empty-string)
                                       (hash-ref json-body 'error_uri empty-string)
                                       (hash-ref json-body 'state empty-string)
                                       (current-continuation-marks)))]
         [else
          (define exn (if (hash-has-key? error-transformers uri)
                          ((hash-ref error-transformers uri) uri json-body (current-continuation-marks))
                          #f))
          (cond
            [(exn:fail:oauth2? exn)
             (raise exn)]
            [else
             (raise (make-exn:fail:oauth2 'unknown
                                          (fourth response)
                                          empty-string
                                          empty-string
                                          (current-continuation-marks)))])])]
      [else
       (raise (apply make-exn:fail:http response))]))
  response)

(define (parse-response status headers in-port)
  (define-values (protocol rest) (string-split-first (bytes->string/utf-8 status) #\space))
  (define-values (code msg) (string-split-first rest #\space))
  (list
   (string->number code)
   msg
   (make-hash 
    (for/list ([header headers])
      (define-values (k v) (string-split-first (bytes->string/utf-8 header) #\:))
      (cons k (string-trim (substring v 1)))))
   (port->bytes in-port)))

(define (token-from-response json)
  (make-token
   (hash-ref json 'access_token)
   (hash-ref json 'token_type)
   (hash-ref json 'refresh_token #f)
   (hash-ref json 'audience #f)
   (string-split (hash-ref json 'scope empty-string) ",")
   (let ([expires-in (hash-ref json 'expires_in "0")])
     (+ (current-seconds) (if (string? expires-in) (string->number expires-in) expires-in)))))
