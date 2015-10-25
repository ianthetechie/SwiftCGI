# SwiftCGI
An object-functional microframework for developing FCGI applications in Swift

## About
Well, the title pretty much says it all. This is a microframework (no, I'm not writing the next Django or Rails),
and it is written in Swift (well, OK, I admit, there is a little bit
of Objective-C in here because I needed a quick socket library; a
better version is in the works, most likely wrapping a more
established C library).

## Why?
A valid question. Mostly because I was bored one weekend. Also, because I am passionate about a couple of things.
First, I love Swift. Call me an Apple fanboy, but I'm a huge fan of the language and think they hit the nail on the
head. Second, I love lasers, but that's not important right now. Third, I am a huge supporter of functional (and
similar derived styles) of programming. Fourth, I think that Swift is going to (eventually) bring functional
programming within reach of the "normal" programmer who can't convince his boss to let him rewrite the company
intranet in some arcane Haskell framework (which would be crazy awesome, but might not be maintainable by your
average kid out of school; Swift OTOH is). My primary work, writing iOS apps, can now be done in a functional style
thanks to Swift, and it's AWESOME. Which leads me to the final reason that I will bore you with: I hate programming
web apps. I did it for way too many years. It scarred me for life. But I may be convinced to go back at some point
after my JavaScript hangover wears off and I can write server-side code in a framework that is not bloated and works
well with a functional approach.

## Vision
SwiftCGI will eventually become a mature, modular microframework that encourages a functional approach to developing
web apps in Swift. The design will be as modular as possible so that "pieces" can be assembled to form a fuller
framework as desired. Eventually, it will have an ORM API (still hashing out the design decisions there so that it
will work well with both relational and non-relational databases) and a few other niceties, but don't expect this to
have as many features as Django.

## Current status
I would currently classify SwiftCGI as late alpha in that it is a funcitonal base that mostly modular design, is
(mostly) unit tested, but is still somewhat incomplete. It is not ready for prime time yet, so expect things to
change somewhat over the next few months (not quite as fast as Swift has been changing, but not quite as stable as
the C++ spec). NOTE: The current server has the same limitations of FCGIKit, which will be remedied in the future.

The project and demos are currently Swift 2.0 compatible, but not everything has been updated to capture the true
spirit of Swift 2.0. This is in the works.

## Credits
I'm not sure I'd say this project was "inspired" by [FCGIKit](https://github.com/fervo/FCGIKit), but the core of this
project started as a port of (and is still heavily influenced by) FCGIKit. I started off by porting FCGIKit to Swift,
and have since rewritten a lot of things to be more "Swifty." I chose this path because I don't want to re-invent
the wheel. I may do a Swift wrapper around a canonical C implementation in the future to ensure the correctness of the implementation.

# Getting Started
1. Clone the repo
2. Open the SwiftCGI Demo workspace
3. Switch the target to SwiftCGIDemo if necessary
4. Run the project
5. [RECOMMENDED] Configure nginx to serve fcgi from your application (a full nginx tutorial may come later if I get
   bored, but for now, the following nginx.conf snippet should suffice... Put this inside your server block).
   Alternatively, you may use the embedded HTTP server scheme, which starts a (rather expreimental a this point)
   local HTTP server, which can be used to get started. I do NOT recommend this for serious use though. SwiftCGI is
   designed, first and foremost, for FCGI app development.

```
location /cgi {
    fastcgi_pass    localhost:9000;
    fastcgi_param   SCRIPT_FILENAME /scripts$fastcgi_script_name;
    include         fastcgi_params;
}
```


## License This project is distributed under the terms of the 2-clause
BSD license. TL;DR - if the use of this product causes the death of
your firstborn, I'm not responsible (it is provided as-is; no warranty,
liability, etc.) and if you redistribute this with or without
modification, you need to credit me and copy the license along with
the code. Otherwise, you can pretty much do what you want ;)
