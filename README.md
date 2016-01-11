# SwiftCGI [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

An object-functional microframework for developing FCGI applications in Swift

## About

Well, the title pretty much says it all. This is a microframework (no,
not the next Django or Rails), and it is written in Swift (well, OK, I
admit, there is a little bit of Objective-C in here because I needed a
quick socket library; a better version is in the works, most likely
wrapping a more established C library).

## Why?

A valid question. Mostly because I was bored one weekend. Also,
because I am passionate about a couple of things.  First, I love
Swift. Apple hit the nail on the head. Second, I love lasers, but
that's not important right now. Third, I am a huge supporter of
functional (and similar derived styles) of programming. Fourth, I
think that Swift is going to bring functional programming within reach
of the "normal" programmer who can't convince his boss to let him
rewrite the company intranet in some arcane Haskell
framework. Finally, I hate programming web apps. I did it for way too
many years. It scarred me for life. But I may be convinced to go back
at some point after my JavaScript hangover wears off and I can write
server-side code in a framework that is not bloated and works well
with a functional approach.

## Vision

SwiftCGI will eventually become a mature, modular microframework that
encourages a functional approach to developing web apps in Swift. The
design will be as modular as possible so that "pieces" can be
assembled to form a fuller framework as desired. I envision an ORM,
authentication plugins, etc. will be written over time, but my focus
right now is the core framework. If the modularity part of the design
works out properly, additional functionality will be relatively easy
to hook in.

## Current status

I would currently classify SwiftCGI as late alpha in that it is a
funcitonal base that mostly modular design, is (mostly) unit tested,
but is still somewhat incomplete. It is not ready for prime time yet,
so expect things to change and occasionally break along the road
to 1.0. NOTE: The current server has the same limitations of FCGIKit,
which will be remedied in the future.

## Credits

I'm not sure I'd say this project was "inspired" by
[FCGIKit](https://github.com/fervo/FCGIKit), but the core of this
project started as a port of (and is still heavily influenced by)
FCGIKit. I started off by porting FCGIKit to Swift, and have since
refactored much of it to be more "Swifty."

# Quick Start

1. Clone the demo project from
   [ianthetechie/SwiftCGI-Demo](https://github.com/ianthetechie/SwiftCGI-Demo).
2. Open the SwiftCGI Demo project.
3. Run the project.
4. [RECOMMENDED] Configure nginx to serve fcgi from your application
   (a full nginx tutorial may come later if I get bored, but for now,
   the following nginx.conf snippet should suffice... Put this inside
   your server block).  Alternatively, you may use the embedded HTTP
   server scheme, which starts a (rather expreimental a this point)
   local HTTP server, which can be used to get started. I do NOT
   recommend this for serious use though. It is still highly
   experimental and rather flawed. SwiftCGI is designed, first and
   foremost, for FCGI app development.

```
location /cgi {
    fastcgi_pass    localhost:9000;
    fastcgi_param   SCRIPT_FILENAME /scripts$fastcgi_script_name;
    include         fastcgi_params;
}
```


## License This project is distributed under the terms of the 2-clause BSD license.

TL;DR - if the use of this product causes the death of
your firstborn, I'm not responsible (it is provided as-is; no warranty,
liability, etc.) and if you redistribute this with or without
modification, you need to credit me and copy the license along with
the code. Otherwise, you can pretty much do what you want ;)
