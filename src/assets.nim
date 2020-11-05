import os


proc computeAssetContents(): seq[(string, string)] =
  for kind, path in walkDir("assets"):
    if kind == pcFile:
      let filename = path.extractFilename()
      let content = staticRead("../assets/" & filename)
      result.add((filename, content))

const assetContents = computeAssetContents()


proc readAsset*(filename: string): string =
  ## Returns the contents of the asset with the given filename. This is
  ## an empty string if no such asset exists.
  for (name, content) in assetContents:
    if name == filename:
      return content


when defined(runTests):
  doAssert readAsset("keepme.txt") == "hello, world!\n"
