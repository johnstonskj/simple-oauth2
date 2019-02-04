#lang racket/base
;;
;; simple-oauth2 - oauth2/client/flow.
;;   Simple OAuth2 client and server implementation
;;
;; Copyright (c) 2019 Simon Johnston (johnstonskj@gmail.com).

(provide initiate-code-flow
         initiate-implicit-flow
         initiate-application-flow
         initiate-password-flow)

;; ---------- Requirements

(require racket/bool
         oauth2
         oauth2/client
         oauth2/storage/clients
         oauth2/storage/config
         oauth2/storage/tokens
         oauth2/private/logging)

;; ---------- Implementation

(define (initiate-code-flow client scopes #:user-name [user-name #f] #:state [state #f] #:challenge [challenge #f] #:audience [audience #f])
  (log-oauth2-info "initiate-code-flow from ~a" (client-service-name client))

  (define response-channel
    (request-authorization-code
     client 
     scopes
     #:state state 
     #:challenge challenge 
     #:audience audience))

  (define authorization-code
    (channel-get response-channel))
  (log-oauth2-debug "received auth-code ~a" authorization-code)

  (when (exn:fail? authorization-code)
    (raise authorization-code))

  (define token-response
    (grant-token/from-authorization-code
     client 
     authorization-code
     #:challenge challenge))
  (log-oauth2-debug "fetch-token/from-code returned ~a" token-response)

  (set-token!
   (if (false? user-name)
       (get-current-user-name)
       user-name)
   (client-service-name client)
   token-response)
  (save-tokens)

  token-response)

(define (initiate-implicit-flow) #f)

(define (initiate-application-flow) #f)

(define (initiate-password-flow) #f)

;; ---------- Internal Procedures

(define (make-authorization-header/for-client client user-name)
  (define token (get-token user-name (client-service-name client)))
  (define a-token 
    (cond
      [(or (false? (token-expires token)
                   (= (token-expires token) -1)))
       (refresh-token client token)]
      [else token]))
  (make-authorization-header a-token))

