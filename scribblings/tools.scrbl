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
protected. They show how the client flows are used in a real application as well
as providing a framework for tools to use. 

All tools need to determine their authorization state, which can be one of:

@itemlist[
 @item{@italic{no client} - either no client stored for the service, or the
  client has no @tt{id} and @tt{secret} stored.}
 @item{@italic{no token} - the client is fully configured but has not been
  used to fetch an authoriztion token.}
 @item{@italic{authorized} - both the client and token are present in the
  persistent storage.}
 #:style 'ordered]

If the tools detect either of the first two states the tool will not perform
any protected calls, but force the use of the @tt{-i} and @tt{-s} flags to use the
client details to perform the code grant flow.

@verbatim|{
  $ fitbit -i HDGGEX -s SGVsbG8gV29ybGQgZnJvbSBTaW1vbgo=
Fitbit returned authenication token: I2xhbmcgcmFja2V0L2Jhc2UKOzsKOzsg\
c2ltcGxlLW9hdXRoMiAtIHNpbXBsZS1vYXV0aDIuCjs7ICAgU2ltcGxlIE9BdXRoMiBjb\
GllbnQgYW5kIHNlcnZ
}|

All of the tools share two output formatting arguments; firstly specifying an
output format (using @tt{-f} which defaults to CSV) and output file to write
to (using @tt{-o}).

@;{============================================================================}
@section[]{Fitbit client}

This client implements simple queries against the
@hyperlink["https://dev.fitbit.com/build/reference/web-api/"]{Fitbit API}.
Once the client has been authorized and the token stored, the tool will
perform queries against the @tt{sleep} and @tt{weight} scope. Queries support
a common set of arguments to specify either a single data (using @tt{-s}, which
defaults to the current data) or a data range (using @tt{-s} and @tt{-e}).

@verbatim|{
  $ fitbit -h
fitbit [ <option> ... ] <scope>
 where <option> is one of
/ -v, --verbose : Compile with verbose messages
\ -V, --very-verbose : Compile with very verbose messages
  -s <start>, --start-date <start> : Start date (YYYY-MM-DD)
  -e <end>, --end-date <end> : End date (YYYY-MM-DD)
  -u <units>, --units <units> : Unit system (US, UK, metric)
  -f <format>, --format <format> : Output format (csv)
  -o <path>, --output-file <path> : Output file
  --help, -h : Show this help
}|

The following example retrieves the sleep record for a data range as CSV.

@verbatim|{
  $ fitbit -s 2018-07-16 -e 2018-07-21 sleep
date,start,minbefore,minasleep,minawake,minafter,efficiency,deep:min,\
deep:avg,deep:count,light:min,light:avg,light:count,rem:min,rem:avg, \
rem:count,wake:min,wake:avg,wake:count
2018-07-17,2018-07-16T23:42:00.000,0,494,40,1,97,122,0,6,197,0,21,175\
,0,6,40,0,20
}|


The following retrieves the current dates weight record formatted as an
on-screen table.

@verbatim|{
  $ fitbit -f screen weight
date       | time     | weight | bmi   | fat
-----------+----------+--------+-------+------------------
2019-02-05 | 15:04:16 | 262.2  | 35.59 | 39.25299835205078
}|
