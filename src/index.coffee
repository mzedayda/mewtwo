_ = require "lodash"
Async = require "async"
Redfour = require "redfour"

MultiLock = require "./multiLock"

internals = {}

internals.defaults =
  timeout: 5 * 60 * 1000 # 5 minutes
  redfour: { redis: "redis://localhost:6379", namespace: "mewtwo" }

module.exports = class Mewtwo
  constructor: (options) ->
    options = _.defaults options, internals.defaults

    @timeout = options.timeout
    @locker = new Redfour options.redfour

    @selfLockName = "__mewtwo__"

  acquire: (keys, done) ->
    success = false
    selfLock = result = error = null

    Async.series
      selfAcquire: (next) =>
        @locker.waitAcquireLock @selfLockName, 10000, 1000, (err, lock) =>
          return next(err) if err?
          return next("selfLock locked") unless lock?.success
          selfLock = lock
          next()

      acquire: (next) =>
        keys = [keys] unless _.isArray(keys)
        keys = _.uniq keys

        Async.map keys, (key, next) =>
          @locker.acquireLock key, @timeout, (err, singleLock) ->
            return next(err) if err?
            return next("#{key} is locked") unless singleLock.success
            next(null, singleLock)
        , (err, singleLocks) =>
          if err?
            @_release singleLocks, (releaseErr) ->
              if releaseErr? then error = "releaseErr: #{releaseErr}" else error = err
              next()
          else
            result = new MultiLock(singleLocks)
            next()
    , (err) =>
      return done(err) unless selfLock?

      @locker.releaseLock selfLock, (err) ->
        return done(err) if err?
        done(error, result)

  release: (multiLock = new MultiLock([]), done) ->
    @_release multiLock.singleLocks, done

  _release: (singleLocks, done) ->
    Async.each singleLocks, (singleLock, next) =>
      return @locker.releaseLock singleLock, next if singleLock?.success
      next()
    , done
