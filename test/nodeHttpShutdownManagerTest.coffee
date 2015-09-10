expect = require("chai").expect
EventEmitter = require("events").EventEmitter

describe "Shutdown Handler", () ->
    NodeHttpShutdownManager = require "../lib/nodeHttpShutdownManager"

    it "should initialize all necessary variables", () ->
        svr = new EventEmitter()
        t = new NodeHttpShutdownManager svr
        expect(t.server).to.equal(svr)
        expect(t.numOpenConnections).to.equal(0)
        expect(t.numOpenRequests).to.equal(0)
        expect(t.totalConnections).to.equal(0)
        expect(t.totalRequests).to.equal(0)


    it "should reset counts when requested", () ->
        t = new NodeHttpShutdownManager()
        t.totalConnections = 5
        t.totalRequests = 10
        t.reset()
        expect(t.totalConnections).to.equal(0)
        expect(t.totalRequests).to.equal(0)

        t.numOpenConnections = 2
        t.numOpenRequests = 1
        t.totalConnections = 5
        t.totalRequests = 10
        t.reset()
        expect(t.totalConnections).to.equal(2)
        expect(t.totalRequests).to.equal(1)

    it "should track connections and requests", () ->
        svr = new EventEmitter()
        s = new EventEmitter()
        req = connection: s
        res = new EventEmitter()
        t = new NodeHttpShutdownManager svr

        svr.emit "connection", s
        expect(t.numOpenConnections).to.equal(1)
        expect(t.numOpenRequests).to.equal(0)
        expect(t.totalConnections).to.equal(1)
        expect(t.totalRequests).to.equal(0)

        svr.emit "request", req, res
        expect(t.numOpenConnections).to.equal(1)
        expect(t.numOpenRequests).to.equal(1)
        expect(t.totalConnections).to.equal(1)
        expect(t.totalRequests).to.equal(1)

        res.emit "finish"
        expect(t.numOpenConnections).to.equal(1)
        expect(t.numOpenRequests).to.equal(0)
        expect(t.totalConnections).to.equal(1)
        expect(t.totalRequests).to.equal(1)

        s.emit "close"
        expect(t.numOpenConnections).to.equal(0)
        expect(t.numOpenRequests).to.equal(0)
        expect(t.totalConnections).to.equal(1)
        expect(t.totalRequests).to.equal(1)

    it "should shutdown if there are no requests (callback)", (cb) ->
        t = new NodeHttpShutdownManager
        t.shutdown cb

    it "should shutdown if there are no requests (promise)", (cb) ->
        t = new NodeHttpShutdownManager
        t.shutdown()
        .then () -> cb()

    it "should tolerate multiple calls to shutdown", (cb) ->
        t = new NodeHttpShutdownManager

        cb1 = () ->
            t.cb1 = true
            if t.cb1 && t.cb2 then cb()
        cb2 = () ->
            t.cb2 = true
            if t.cb1 && t.cb2 then cb()

        t.shutdown(cb1)
        t.shutdown(cb2)



    it "should close server shutdown", (cb) ->
        svr = new EventEmitter()
        svr.close = () -> @closed = true
        t = new NodeHttpShutdownManager svr
        t.shutdown()
        .then () ->
            expect(svr.closed).to.equal(true)
            cb()

    it "should shutdown idle open connections on shutdown", (cb) ->
        svr = new EventEmitter()
        svr.close = () ->
        s = new EventEmitter()
        t = new NodeHttpShutdownManager svr

        s.destroy = () ->
            expect(@destroyed).to.equal(undefined)
            @destroyed = true
            @emit "close"

        svr.emit "connection", s
        t.shutdown()
        .then () ->
            expect(s.destroyed).to.equal(true)
            cb()

    it "should wait for requests to finish", (cb) ->
        svr = new EventEmitter()
        s = new EventEmitter()
        req = connection: s
        res = new EventEmitter()
        t = new NodeHttpShutdownManager svr

        svr.close = () -> @closed = true

        s.destroy = () ->
            expect(svr.closed).to.equal(true)
            expect(@destroyed).to.equal(undefined)
            @destroyed = true
            @emit "close"

        svr.emit "connection", s
        svr.emit "request", req, res

        t.shutdown()
        .then () ->
            expect(svr.closed).to.equal(true)
            expect(req.finished).to.equal(true)
            expect(s.destroyed).to.equal(true)
            cb()

        finish = () ->
            expect(svr.closed).to.equal(true)
            expect(req.finished).to.equal(undefined)
            expect(s.destroyed).to.equal(undefined)
            req.finished = true
            res.emit "finish"
        setTimeout finish, 25
