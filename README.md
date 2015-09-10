[![Build Status](https://travis-ci.org/UberEther/node-http-shutdown-manager.svg?branch=master)](https://travis-ci.org/UberEther/node-http-shutdown-manager)
[![NPM Status](https://badge.fury.io/js/node-http-shutdown-manager.svg)](http://badge.fury.io/js/node-http-shutdown-manager)

# Overview

This library provides a class to coordinate an orderly shutdown for Node.js HTTP servers.  It does so by tracking the open connections and requests,
and when a shutdown is requested, it closes connections with no open requests and closes other connections once all requests are complete.

Note that in case a request is stuck, you should always have a timeout on your shutdowns.  Consider using [node-shutdown-events](https://github.com/UberEther/node-shutdown-events) to provide for a clean way to hook into the shutdown chain.

This was inspired by [code from JoshuaWise](https://github.com/joyent/node/issues/9066).

# Examples of use:

```
var HttpShutdownManager = require("node-http-shutdown-manager");
var http = require("http");

// Option 1 - let the ShutdownManager create the server
var mgr = new HttpShutdownManager();
var svr = mgr.server;

// Option 2 - create it yourself
var svr = http.createServer();
var mgr = new HttpShutdownManager(svr);

// When ready to shutdown...
mgr.shutdown(function() { console.log("HTTP server cleanly shutdown") });

// To use the promise:
mgr.shutdown()
.then(function() { console.log("HTTP server cleanly shutdown") });

// To use with node-shutdown-events:
process.on("shutdown", mgr.shutdown.bind(mgr));
```

# API

## new HttpShutdownManager(http = http.createServer())
Creates a new shutdown manager for the specified server.
- If no server is specified, one is created - the server can be accessed at ```.server```
- You must do this **before** you start listening on the server

Member variables of public interest:
- server: Server being managed
- numOpenConnections - Number of currently open connections to the server
- numOpenRequests - Number of currently open requests to the server
- totalConnections - Total number of connections opened against the server (includes currently open connections)
- totalRequests - Total number of requests submitted to the server (includes pending requests)

## reset()
Resets total counts for the server

## shutdown(cb)
Closes the server and proceedes to start closing connections.  Once all connections are closed, the callback is called.

Returns a promise that is resolved when all connections are closed.

# Contributing

Any PRs are welcome but please stick to following the general style of the code and stick to [CoffeeScript](http://coffeescript.org/).  I know the opinions on CoffeeScript are...highly varied...I will not go into this debate here - this project is currently written in CoffeeScript and I ask you maintain that for any PRs.