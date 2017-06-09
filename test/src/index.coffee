should = require("chai").should()
Async = require "async"

Mewtwo = require "../../"

describe "mewtwo", ->
  before ->
    @mew = new Mewtwo({ log: false, timeout: 5000 })

    @releaseLock = (lock, done) =>
      @mew.release lock, done

  it "should lock a single key", (done) ->
    @mew.acquire "key1", (err, multiLock) =>
      return done(err) if err?
      multiLock.singleLocks.should.have.length 1
      multiLock.singleLocks[0].success.should.be.true
      @releaseLock multiLock, done

  it "should ignore duplicated keys", (done) ->
    @mew.acquire ["key1", "key1"], (err, multiLock) =>
      return done(err) if err?
      multiLock.singleLocks.should.have.length 1
      multiLock.singleLocks[0].success.should.be.true
      @releaseLock multiLock, done

  it "should lock multiple keys", (done) ->
    @mew.acquire ["key1", "key2"], (err, multiLock) =>
      return done(err) if err?
      multiLock.singleLocks.should.have.length 2
      multiLock.singleLocks[0].success.should.be.true
      multiLock.singleLocks[1].success.should.be.true
      @releaseLock multiLock, done

  it "should not allow locking a key twice", (done) ->
    @mew.acquire ["key1", "key2"], (err, multiLock) =>
      return done(err) if err?
      @mew.acquire "key1", (err, multiLock2) =>
        err.should.equal "key1 is locked"
        should.not.exist multiLock2
        @releaseLock multiLock, done

  it "should allow locking a key twice if it was previously released", (done) ->
    Async.series
      lockAndRelease: (next) =>
        @mew.acquire "key1", (err, lock1) =>
          return next(err) if err?
          @releaseLock lock1, next

      lock2: (next) =>
        @mew.acquire "key1", (err, lock2) =>
          return next(err) if err?
          lock2.singleLocks.should.have.length 1
          lock2.singleLocks[0].success.should.be.true
          @releaseLock lock2, next
    , done

  it "should only lock keys if all of them are not locked", (done) ->
    locksToRelease = []

    Async.series
      lock1: (next) =>
        @mew.acquire ["key1", "key2"], (err, lock1) ->
          return next(err) if err?
          lock1.singleLocks.should.have.length 2
          lock1.singleLocks[0].success.should.be.true
          lock1.singleLocks[1].success.should.be.true
          locksToRelease.push lock1
          next()

      lock2: (next) =>
        @mew.acquire ["key3", "key2"], (err, lock2) ->
          err.should.equal "key2 is locked"
          should.not.exist lock2
          next()

      lock3: (next) =>
        @mew.acquire "key3", (err, lock3) ->
          lock3.singleLocks.should.have.length 1
          lock3.singleLocks[0].success.should.be.true
          locksToRelease.push lock3
          next()
    , (err) =>
      Async.each locksToRelease, @releaseLock, (err2) ->
        done(err ? err2)

  it "should not throw when no lock is given to release", (done) ->
    @mew.release null, done
