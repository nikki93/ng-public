proc echoInC(msg: cstring) {.importc, discardable.}

echo "hello from nim!"

echoInC "hello from nim, through c!"
