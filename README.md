## mewtwo

A small redis multi-key semaphore lib for nodejs, based on the redfour library

<img src="./images/mewtwo.png" />

## Prequisites

Written in coffeescript, so a coffee compiler is needed to build

```sh
npm install -g coffee-script
```

## Install

```sh
npm install mewtwo --save
```

## Usage example

```coffeescript
Mewtwo = require "mewtwo"

mew = new Mewtwo
  log: true                         # Log stats for each acquire.
  timeout: 5000                     # Locks expire after 5 seconds
  redfour:                          # Initialization options for redfour
    redis: "redis://localhost:6379"
    namespace: "mewtwo" 

mew.acquire ["key2", "key3"], (err, multiLock) =>
  if err
    console.log "Error acquiring: #{err}"
  else
    console.log "key1 & key2 are successfuly locked"

# Another process might try to lock a similar set of keys
mew.acquire ["key1", "key2"], (err, multiLock) =>
  # err equals "key2 is locked"
  # key1 remains unlocked
  # multiLock is null


# When done using the resource, keys can be unlocked with
mew.release multiLock, (err) ->
  if !err
    console.log "multiLock unlocked successfuly"
```

Check out tests for more details.
