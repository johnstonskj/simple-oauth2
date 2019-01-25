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
@title[]{Module oauth2/storage/config.}
@defmodule[oauth2/storage/config]

@examples[ #:eval example-eval
(require oauth2)
; add more here.
]

@;{============================================================================}
@;Add your API documentation here...


@;{============================================================================}
@title[]{Module oauth2/storage/clients.}
@defmodule[oauth2/storage/clients]

@;{============================================================================}
@title[]{Module oauth2/storage/profiles.}
@defmodule[oauth2/storage/profiles]

