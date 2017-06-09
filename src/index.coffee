Redfour = require "redfour"

testLock = new Redfour
  redis: 'redis://localhost:6379',
  namespace: 'mylock'

id = Math.random();
firstlock = 0