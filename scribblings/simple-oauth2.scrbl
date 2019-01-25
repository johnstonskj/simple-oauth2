#lang scribble/manual

@(require racket/file scribble/core)

@;{============================================================================}

@title[#:version "1.0"]{Package simple-oauth2.}
@author[(author+email "Simon Johnston" "johnstonskj@gmail.com")]

Simple OAuth2 client and server implementation

@table-of-contents[]

@include-section["oauth2.scrbl"]

@include-section["storage.scrbl"]

@section{License}

@verbatim|{|@file->string["../LICENSE"]}|