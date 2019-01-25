#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          simple-oauth2
          (for-label racket/base
                     racket/contract
                     simple-oauth2))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/string
                                oauth2)))

@;{============================================================================}
@title[]{Module oauth2.}
@defmodule[oauth2]

Simple OAuth2 client and server implementation

@examples[ #:eval example-eval
(require oauth2)
; add more here.
]

@;{============================================================================}
@;Add your API documentation here...


@;{============================================================================}
@title[]{Module oauth2/client.}
@defmodule[oauth2/client]

@;{============================================================================}
@title[]{Module oauth2/client-flow.}
@defmodule[oauth2/client-flow]

