#lang scribble/manual

@(require racket/sandbox
          scribble/core
          scribble/eval
          (for-label racket/base
                     racket/contract))

@;{============================================================================}
@(define example-eval (make-base-eval
                      '(require racket/string
                                oauth2)))

@;{============================================================================}
@title[]{Example Command Line Tools}

The following are tools to access commonly-used services that are OAuth 2.0
protected.

@;{============================================================================}
@section[]{Fitbit client}

This client implements simple queries against the
@hyperlink["https://dev.fitbit.com/build/reference/web-api/"]{Fitbit API}.
