#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract
                     oauth2
                     oauth2/client
                     oauth2/client/flow))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/string
                                oauth2)))

@;{============================================================================}
@title[]{OAuth 2.0 Client}

Simple OAuth2 client and server implementation

@examples[ #:eval example-eval
(require oauth2 oauth2/client)
; add more here.
]

@;{============================================================================}
@section[]{Module oauth2/client.}
@defmodule[oauth2/client]


@;{============================================================================}
@section[]{Module oauth2/client/flow.}
@defmodule[oauth2/client/flow]
