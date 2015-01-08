# SwiftCGI
An FCGI microframework in Swift

## About
Well, the title pretty much says it all. This is a microframework (no, I'm not writing the next Django or Rails),
and it is written in Swift (OK, I confess, it's not 100% Swift... I saw no need to throw out the perfectly good
piece of work that is GCDAsyncSocket, but dependencies aside, it's all Swift :D).

## Why?
A valid question. Mostly because I was bored last weekend. Also, because I am passionate about a couple of things.
First, I love Swift. Call me an Apple fanboy, but I'm a huge fan of the language and think they hit the nail on the
head. Second, I love lasers, but that's not important right now. Third, I am a huge supporter of functional (and
similar derived styles) of programming. Fourth, I think that Swift is going to (eventually) bring functional
programming within reach of the "normal" programmer who can't convince his boss to let him rewrite the company
intranet in some arcane Haskell framework (which would be crazy awesome, but might not be maintainable by your
average kid out of school; Swift OTOH is). I'm already starting to write iOS apps in a functional style thanks to
Swift, and it's AWESOME. Which leads me to the final reason that I will bore you with: I hate programming web apps.
I did it for way too many years. It scarred me for life. But I may be convinced to go back at some point after my
JavaScript hangover wears off and I can write server-side code in a framework that is not bloated and works well with
a functional approach.

## Vision
SwiftCGI will eventually become a mature, modular microframework that encourages a functional approach to developing
web apps in Swift. The design will be as modular as possible so that "pieces" can be assembled to form a fuller
framework as desired. Eventually, it will have an ORM API (still hashing out the design decisions there so that it
will work well with both relational and non-relational databases) and a few other niceties, but don't expect this to
have as many features as Django.

## Current status
I wrote this in a couple evenings of spare time. Don't judge too hard yet ;) By the end of January, I hope to
reach alpha status in that it is a funcitonal base that exhibits proper modular design, is unit tested, etc.
The first couple dozen or so commits will involve a lot of Swift-ifying the FCGI core, which, at least to
start, is basically a port of FCGIKit, which brings me to the credits. (NOTE: As such, the current server
has the same limitations of FCGIKit, and probably a few bugs as well. I've already identified and fixed several.)

## Credits
I'm not sure I'd say this project was "inspired" by [FCGIKit](https://github.com/fervo/FCGIKit), but the core of
the base of this project is a port of FCGIKit that will be improved and Swift-ified as it is developed and "finished" (FCGIKit is a very minimal implementation, which made a great base for learning how to write an FCGI server, but will
need to be improved upon for serious use). I feel it's a lot safer to port a minimal Obj-C implementation and go from
there rather than trying to wrap the fcgi C library.

# Getting Started
1. Clone the repo
2. Open the SwiftCGIDemo workspace
3. Admire the elegance of main.swift (it's so short!!!)
4. Switch the target to SwiftCGIDemo
5. Run the project
6. Configure nginx to serve fcgi from your application (localhost, port 9000, set up an endpoint, etc. nginx tutorial may come later if I get bored, but it'd probably be faster for you to just google how to set up an nginx fastcgi server)

# License
Copyright (c) 2014, Ian Wagner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that thefollowing conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
