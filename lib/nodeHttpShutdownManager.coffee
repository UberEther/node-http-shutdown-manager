http = require "http"
events = require "events"
Promise = require "bluebird"

class NodeHttpShutdownManager extends events.EventEmitter
    constructor: (@server = http.createServer()) ->
        @setMaxListeners 0
        @numOpenConnections = 0
        @numOpenRequests = 0
        @totalConnections = 0
        @totalRequests = 0

        @server.on "connection", @_onConnection.bind @
        @server.on "request", @_onRequest.bind @

    reset: () ->
        @totalConnections = @numOpenConnections
        @totalRequests = @numOpenRequests

    shutdown: (cb) ->
        return @shutdownPromise.nodeify(cb) if @shutdownPromise
        self = @
        @shutdownPromise = new Promise (resolve) ->
            self.server.close()
            if !self.numOpenConnections then resolve()
            else
                self.shutdownCallback = resolve
                self.emit "shutdown"
        .nodeify cb

        return @shutdownPromise

    _onConnection: (socket) ->

        @numOpenConnections++
        @totalConnections++
        socket.numOpenRequests = 0

        destroy = () ->
            socket.destroy() if !socket.numOpenRequests

        self = @
        onClose = () ->
            self.numOpenConnections--
            self.removeListener "shutdown", destroy
            if !self.numOpenConnections and self.shutdownCallback then self.shutdownCallback()

        @once "shutdown", destroy
        socket.once "close", onClose

    _onRequest: (req, res) ->
        socket = req.connection
        @totalRequests++
        @numOpenRequests++
        socket.numOpenRequests++

        self = @
        onFinish = () ->
            self.numOpenRequests--
            socket.numOpenRequests--
            if self.shutdownPromise then socket.destroy()

        res.on "finish", onFinish.bind @




module.exports = NodeHttpShutdownManager
