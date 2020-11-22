## Interface to real-time rendering for the entire application.
##
## Responsibilities
## ================
##
## - Manages the **window** and the associated **renderer**.
## - Manages **resources** such as images and effects for drawing.
## - Has procedures to **perform the actual drawing**. Coordinates are
##   generally in **world-space**, and subject to a **view transformation**
##   when drawn.
## - Manages the current **drawing state** which includes properties that
##   affect the next draw call (such as view, color, ...). States can be
##   **scoped** with `gfx.scope`.
## - Has **utilities** to get the view and window dimensions and convert
##   between coordinate spaces.


import std/[tables, hashes]

import utils


const sdlH = "\"precomp.h\""

const gpuH = "\"precomp.h\""

type
  SDLWindow {.importc: "SDL_Window", header: sdlH.} = object


  GPUContext {.importc: "GPU_Context", header: gpuH.} = object
    default_textured_vertex_shader_id: uint32

  GPUTarget {.importc: "GPU_Target", header: gpuH.} = object
    w: uint16
    context: ptr GPUContext

  SDLColor {.importc: "SDL_Color", header: sdlH.} = object
    r, g, b, a: uint8

  GPURect {.importc: "GPU_Rect", header: gpuH.} = object
    x, y, w, h: float32

  GPUImage {.importc: "GPU_Image", header: gpuH.} = object
    w, h: uint16

  GPUShaderBlock {.importc: "GPU_ShaderBlock", header: gpuH.} = object
    position_loc, texcoord_loc, color_loc, modelViewProjection_loc: int

  GPUShaderEnum {.importc: "GPU_ShaderEnum", header: gpuH.} = enum
    VertexShader = 0
    FragmentShader = 1

  GPUSnapEnum {.importc: "GPU_SnapEnum", header: gpuH.} = enum
    None = 0

  GPUFilterEnum {.importc: "GPU_FilterEnum", header: gpuH.} = enum
    LinearMipmap = 2

  Texture = object
    gpuImage: ptr GPUImage
    path: string
    handleCount: int
    blobUrl: string

  Image* = object
    tex: ptr Texture

  Uniform = object
    name: string
    nameHash: Hash
    gpuId: int

  Program = object
    gpuProgId: uint32
    gpuBlock: GPUShaderBlock
    uniforms: seq[Uniform]
    path: string
    handleCount: int
    gfx: ptr Graphics

  Effect* = object
    prog: ptr Program


  State = object
    r, g, b, a: uint8
    viewX, viewY: float
    viewWidth, viewHeight: float
    prog: ptr Program

  Graphics = object
    window: ptr SDLWindow
    screen: ptr GPUTarget

    renderScale: float
    state: State

    texs: Table[string, ref Texture]
    progs: Table[string, ref Program]


# Coordinates

proc SDL_GetWindowSize(window: ptr SDLWindow, w, h: var cint)
  {.importc, header: sdlH.}

proc GPU_SetWindowResolution(w, h: uint16)
  {.importc, header: gpuH.}

proc view*(gfx: Graphics): (float, float, float, float) {.inline.} =
  ## Get the current rectangular view region in world-space.
  (result[0], result[1]) = (gfx.state.viewX, gfx.state.viewY)
  (result[2], result[3]) = (gfx.state.viewWidth, gfx.state.viewHeight)

proc viewToWorld*(gfx: Graphics, x, y: float): (float, float) {.inline.} =
  ## Convert the position expressed in view-space to world-space.
  result[0] = x - 0.5 * gfx.state.viewWidth + gfx.state.viewX
  result[1] = y - 0.5 * gfx.state.viewHeight + gfx.state.viewY

proc windowSize*(gfx: Graphics): (float, float) {.inline.} =
  ## Get the size of the window (in the operating system's units --
  ## mostly useful for aspect ratio).
  var w, h: cint
  SDL_GetWindowSize(gfx.window, w, h)
  (w.toFloat, h.toFloat)

proc selectWindowSize(gfx: var Graphics): (int, int) =
  var bestW = 800
  when defined(emscripten):
    proc JS_getCanvasWidth(): int
      {.importc.}
    bestW = JS_getCanvasWidth()
  (bestW, (bestW.toFloat * gfx.state.viewHeight / gfx.state.viewWidth).toInt)

proc updateRenderScale(gfx: var Graphics) {.inline.} =
  let screenW = cast[int](gfx.screen.w).toBiggestFloat
  gfx.renderScale = screenW / gfx.state.viewWidth


# Image

proc `=copy`(a: var Texture, b: Texture) {.error.}

proc `=copy`(a: var Image, b: Image) {.error.}

proc `=destroy`(tex: var Texture) =
  # Free the GPU data associated with this texture
  if tex.gpuImage != nil:
    proc GPU_FreeImage(image: ptr GPUImage)
      {.importc, header: gpuH.}
    GPU_FreeImage(tex.gpuImage)
  destroyFields(tex)

proc `=destroy`(img: var Image) =
  # User code just dropped an image handle. Decrement the handle count
  # of the associated texture.
  if img.tex != nil:
    dec img.tex.handleCount
  destroyFields(img)

proc initImage(tex: ptr Texture): Image =
  ## Create a new image handle associated with the given texture.
  ## Increments the handle count for the texture.
  inc tex.handleCount
  result.tex = tex

proc copy*(img: Image): Image =
  ## Explicitly create a copy of this image handle
  initImage(img.tex)

proc loadImage*(gfx: var Graphics, path: string): Image =
  ## Load an `Image` from the file at the given path. If an image for
  ## that file is already currently loaded, this just returns another
  ## handle to that data and is quick.

  # Check existing textures
  let found = gfx.texs.getOrDefault(path)
  if found != nil:
    return initImage(found[].addr)

  # Didn't find existing texture. Load a new one and remember it.
  proc GPU_LoadImage(filename: cstring): ptr GPU_Image
    {.importc, header: gpuH.}
  let gpuImage = GPU_LoadImage(path)
  let tex = (ref Texture)(gpuImage: gpuImage)
  tex.path = path # Separate statement prevents extra copy perf warning
  result = initImage(tex[].addr) # Do this first to prevent copying `tex`
  gfx.texs[path] = tex

  # Smoother image filtering by default
  proc GPU_SetSnapMode(image: ptr GPUImage, snap: GPUSnapEnum)
    {.importc, header: gpuH.}
  GPU_SetSnapMode(gpuImage, GPUSnapEnum.None)
  proc GPU_SetImageFilter(image: ptr GPUImage, filter: GPUFilterEnum)
    {.importc, header: gpuH.}
  GPU_SetImageFilter(gpuImage, GPUFilterEnum.LinearMipmap)

proc size*(img: Image): (float, float) =
  result[0] = cast[int](img.tex.gpuImage.w).toBiggestFloat
  result[1] = cast[int](img.tex.gpuImage.h).toBiggestFloat

proc blobUrl*(img: Image): lent string =
  ## Get a URL for a DOM blob object containing the image. Can be used
  ## for the `src` attribute of an `img` DOM element. Returns an empty
  ## string on non-browser targets.
  when defined(emscripten):
    if img.tex.blobUrl == "":
      proc JS_getBlobUrl(path: cstring): cstring
        {.importc.}
      let cBlobUrl = JS_getBlobUrl(img.tex.path)
      img.tex.blobUrl = $cBlobUrl
      proc free(s: pointer) {.importc.}
      free(cBlobUrl)
    return img.tex.blobUrl
  else:
    let empty {.global.} = ""
    return empty

proc path*(img: Image): lent string {.inline.} =
  img.tex.path
  

# Effect

proc `=copy`(a: var Program, b: Program) {.error.}

proc `=copy`(a: var Effect, b: Effect) {.error.}

proc `=destroy`(prog: var Program) =
  # Free the GPU data associated with this program
  if prog.gpuProgId != 0:
    proc GPU_FreeShaderProgram(prog: uint32)
      {.importc, header: gpuH.}
    GPU_FreeShaderProgram(prog.gpuProgId)
  destroyFields(prog)

proc `=destroy`(eff: var Effect) =
  # User code just dropped an effect handle. Decrement the handle count
  # of the associated program.
  if eff.prog != nil:
    dec eff.prog.handleCount
  destroyFields(eff)

proc initEffect(prog: ptr Program): Effect =
  ## Create a new effect handle associated with the given program.
  ## Increments the handle count for the program.
  inc prog.handleCount
  result.prog = prog

proc loadEffect(gfx: var Graphics, path: string, code: string): Effect =
  # Version of `loadEffect*` below with the `static` param erased so that
  # the compiler doesn't generate all this code for each string.

  # Check existing programs
  let found = gfx.progs.getOrDefault(path)
  if found != nil:
    return initEffect(found[].addr)

  # Compile fragment shader and link with default textured vertex shader
  var errors: string
  proc GPU_CompileShader(shaderType: GPUShaderEnum, source: cstring): uint32
    {.importc, header: gpuH.}
  proc GPU_GetShaderMessage(): cstring
    {.importc: "(char *)GPU_GetShaderMessage", header: gpuH.}
  let fragId = GPU_CompileShader(FragmentShader, code)
  if fragId == 0:
    errors.add("error compiling '" & path & "':\n")
    errors.add(GPU_GetShaderMessage())
  let vertId = gfx.screen.context.default_textured_vertex_shader_id
  proc GPU_LinkShaders(shader1, shader2: uint32): uint32
    {.importc, header: gpuH.}
  let gpuProgId = GPU_LinkShaders(vertId, fragId)
  if gpuProgId == 0:
    errors.add("error linking '" & path & "':\n")
    errors.add(GPU_GetShaderMessage())

  # Preemptively free the fragment shader. The underlying system will
  # actually hold onto it as long as the GPU program exists.
  proc GPU_FreeShader(shader: uint32)
    {.importc, header: gpuH.}
  GPU_FreeShader(fragId)

  # Load the 'shader block' (contains vertex attribute ids)
  proc GPU_LoadShaderBlock(prog: uint32,
    posName, texcoordName, colorName, mvpName: cstring): GPUShaderBlock
    {.importc, header: gpuH.}
  let gpuBlock = GPU_LoadShaderBlock(gpuProgId,
    "gpu_Vertex", "gpu_TexCoord", "gpu_Color",
    "gpu_ModelViewProjectionMatrix")

  # Create our program object, remember it, and return the effect
  let prog = (ref Program)(
    gpuProgId: gpuProgId, gpuBlock: gpuBlock, gfx: gfx.addr)
  prog.path = path # Separate statement prevents extra copy perf warning
  result = initEffect(prog[].addr) # Do this first to prevent copying `prog`
  gfx.progs[path] = prog

  # Notify about errors
  if errors.len > 0:
    echo errors

proc loadEffect*(gfx: var Graphics, path: static string): Effect =
  ## Load an `Effect` based on the shader source file at the given path.
  ## The path must be statically known. The file should be present
  ## alongside the source code files of the application and is read at
  ## compile time.

  # Constant code string with preamble based on platform
  proc prepareCode(path: static string): string =
    when defined(emscripten):
      result.add("""#version 100
  precision highp float;
  precision mediump int;
  #define in varying
  #define texture texture2D
  #define fragColor gl_FragColor
  """)
    else:
      result.add("""#version 150
  out vec4 fragColor;
  """)
    result.add(staticRead(path))
  const code = prepareCode(path)
  gfx.loadEffect(path, code) # Call to version without `static` param


proc useProgram(gfx: var Graphics, prog: ptr Program) =
  ## Use this program when drawing in the current scope. If `nil` the
  ## default program is used.
  if gfx.state.prog == prog:
    return
  gfx.state.prog = prog
  proc GPU_ActivateShaderProgram(prog: uint32, blck: ptr GPUShaderBlock)
    {.importc, header: gpuH.}
  if prog == nil:
    GPU_ActivateShaderProgram(0, nil)
  else:
    GPU_ActivateShaderProgram(prog.gpuProgId, prog.gpuBlock.addr)

proc useEffect*(gfx: var Graphics, effect: Effect) =
  ## Use this effect when drawing in the current scope.
  gfx.useProgram(effect.prog)

proc set(eff: Effect, nameHash: Hash, name: string, value: float) =
  # Version of `set*` below with the `static` param erased so that
  # the compiler doesn't generate all this code for each string.

  let prog = eff.prog
  var uniformId = -1

  # Check if we've already looked up its id
  for uniform in prog.uniforms:
    if uniform.nameHash == nameHash:
      uniformId = uniform.gpuId
      break

  # Look up its id if we need to
  if uniformId == -1:
    proc GPU_GetUniformLocation(prog: uint32, name: cstring): int
      {.importc, header: gpuH.}
    uniformId = GPU_GetUniformLocation(prog.gpuProgId, name)
    if uniformId != -1:
      for uniform in prog.uniforms:
        if uniform.nameHash == nameHash:
          echo "warning: hashes for uniforms '", uniform.name,
            "' and '", name, "' clash!"
      prog.uniforms.add(Uniform(
        name: name, nameHash: nameHash, gpuId: uniformId))

  # If we have an id, let's set the value. We may have to switch to the
  # program and back if it's not currently bound.
  if uniformId != -1:
    var changed = false
    let oldProg = prog.gfx.state.prog
    if oldProg == nil or oldProg.gpuProgId != prog.gpuProgId:
      prog.gfx[].useProgram(prog)
      changed = true
    proc GPU_SetUniformf(location: int, value: float32)
      {.importc, header: gpuH.}
    GPU_SetUniformf(uniformId, value)
    if changed:
      prog.gfx[].useProgram(oldProg)

proc set*(eff: Effect, name: static string, value: float) {.inline.} =
  ## Set a parameter of an effect. The name of the parameter must be
  ## statically known, and should correspond to a uniform in the effect's
  ## shader.
  const nameHash = hash(name)
  eff.set(nameHash, name, value) # Call to version without `static` param


# State

proc setColor*(gfx: var Graphics, r, g, b: uint8, a: uint8 = 0xff) {.inline.} =
  ## Set the color used for drawing in the current scope.
  (gfx.state.r, gfx.state.g, gfx.state.b, gfx.state.a) = (r, g, b, a)

proc setView*(gfx: var Graphics, x, y, w, h: float) {.inline.} =
  ## Set the view rectangle for the current scope. This means drawing
  ## will show up on screen as if viewed from this rectangle. The rectangle
  ## coordinates are in world-space.
  (gfx.state.viewX, gfx.state.viewY) = (x, y)
  (gfx.state.viewWidth, gfx.state.viewHeight) = (w, h)
  gfx.updateRenderScale()

proc setState(gfx: var Graphics, state: State) {.inline.} =
  gfx.setColor(state.r, state.g, state.b, state.a)
  gfx.setView(state.viewX, state.viewY, state.viewWidth, state.viewHeight)
  gfx.useProgram(state.prog)


# Init / deinit

const SDL_INIT_VIDEO = 0x00000020

proc init*(gfx: var Graphics) =
  # Initial state
  gfx.renderScale = 1
  gfx.state = State(
    r: 0xf8, g: 0xf8, b: 0xf2, a: 0xff,
    viewX: 400, viewY: 225,
    viewWidth: 800, viewHeight: 450)

  # Init SDL video
  proc SDL_InitSubSystem(flags: uint32): int
    {.importc, header: sdlH.}
  discard SDL_InitSubSystem(SDL_INIT_VIDEO)

  # In Emscripten, tell SDL to only take keyboard focus when the canvas is
  # focused. Without this it steals keyboard focus from the whole page.
  when defined(emscripten):
    proc SDL_SetHint(nane: cstring, value: cstring): bool
      {.importc, header: sdlH.}
    discard SDL_SetHint("SDL_EMSCRIPTEN_KEYBOARD_ELEMENT", "#canvas")

  # Create window
  let (bestW, bestH) = gfx.selectWindowSize()
  proc SDL_CreateWindow(title: cstring, x, y, w, h: int,
      flags: uint32): ptr SDLWindow
    {.importc, header: sdlH.}
  const SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000
  const SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000
  const SDL_WINDOW_OPENGL = 0x00000002
  gfx.window = SDL_CreateWindow("ng",
      SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
      bestW, bestH,
      SDL_WINDOW_ALLOW_HIGHDPI or SDL_WINDOW_OPENGL)

  # Create renderer
  proc SDL_GetWindowID(window: ptr SDLWindow): uint32
    {.importc, header: sdlH.}
  proc GPU_SetInitWindow(windowId: uint32)
    {.importc, header: gpuH.}
  GPU_SetInitWindow(SDL_GetWindowID(gfx.window))
  var w, h: cint
  SDL_GetWindowSize(gfx.window, w, h)
  const
    gpuDefault {.used.} = 0
    gpuEnableVsync {.used.} = 0x1
    gpuDisableVsync {.used.} = 0x2
    gpuDisableDoubleBuffer {.used.} = 0x4
  var gpuFlags: uint32 = gpuDefault
  when defined(emscripten):
    gpuFlags = gpuDisableVsync or gpuDisableDoubleBuffer
  proc GPU_SetPreInitFlags(flags: uint32)
    {.importc, header: gpuH.}
  GPU_SetPreInitFlags(gpuFlags)
  proc GPU_Init(w, h: uint16, flags: uint32): ptr GPUTarget
    {.importc, header: gpuH.}
  gfx.screen = GPU_Init(cast[uint16](w), cast[uint16](h), 0)
  GPU_SetWindowResolution(cast[uint16](w), cast[uint16](h))

  # Apply initial state
  gfx.setState(gfx.state)

  echo "initialized graphics"

proc deinit*(gfx: var Graphics) =
  # Destroy all resources /before/ deinitializing renderer and window
  gfx.progs.clear()
  gfx.texs.clear()

  # Destroy renderer
  if gfx.screen != nil:
    proc GPU_Quit()
      {.importc, header: gpuH.}
    GPU_Quit()

  # Destroy window and deinit SDL video
  if gfx.window != nil:
    proc SDL_DestroyWindow(window: ptr SDLWindow)
      {.importc, header: sdlH.}
    proc SDL_QuitSubSystem(flags: uint32)
      {.importc, header: sdlH.}
    SDL_DestroyWindow(gfx.window)
    SDL_QuitSubSystem(SDL_INIT_VIDEO)

  echo "deinitialized graphics"


# Draw

proc clear*(gfx: var Graphics, r, g, b: uint8) =
  ## Clear the screen to the given color.
  proc GPU_ClearRGB(target: ptr GPUTarget, r, g, b: uint8)
    {.importc, header: gpuH.}
  GPU_ClearRGB(gfx.screen, r, g, b)

proc worldToRender(gfx: Graphics, x, y: float): (float, float) {.inline.} =
  ## Render-transformed coordinates to pass to renderer
  result[0] = gfx.renderScale *
    (x + 0.5 * gfx.state.viewWidth - gfx.state.viewX)
  result[1] = gfx.renderScale *
    (y + 0.5 * gfx.state.viewHeight - gfx.state.viewY)

proc gpuRect(gfx: var Graphics, x, y, w, h: float): GPURect {.inline.} =
  ## Render-transformed `GPU_Rect` to pass to renderer
  (result.x, result.y) = gfx.worldToRender(x - 0.5 * w, y - 0.5 * h)
  (result.w, result.h) = (gfx.renderScale * w, gfx.renderScale * h)

proc sdlColor(gfx: var Graphics): SDLColor {.inline.} =
  ## Current `SDLColor` to pass to renderer
  SDLColor(r: gfx.state.r, g: gfx.state.g, b: gfx.state.b, a: gfx.state.a)

proc drawImage*(gfx: var Graphics, img: Image, x, y, scale: float) =
  ## Draw the given image with its center at `(x, y)`, with size scaled by
  ## the given scale from its actual dimensions.
  let (imgW, imgH) = img.size
  let w = scale * imgW
  let h = scale * imgH
  proc GPU_BlitRect(image: ptr GPUImage, srcRect: ptr GPURect,
    target: ptr GPUTarget, destRect: var GPURect)
    {.importc, header: gpuH.}
  var destRect = gfx.gpuRect(x, y, w, h)
  GPU_BlitRect(img.tex.gpuImage, nil, gfx.screen, destRect)

proc drawLine*(gfx: var Graphics, x1, y1, x2, y2: float) =
  ## Draw a line from `(x1, y1)` to `(x2, y2)`
  proc GPU_Line(target: ptr GPUTarget,
    x1, y1, x2, y2: float32, color: SDLColor)
    {.importc, header: gpuH.}
  let (rx1, ry1) = gfx.worldToRender(x1, y1)
  let (rx2, ry2) = gfx.worldToRender(x2, y2)
  GPU_Line(gfx.screen, rx1, ry1, rx2, ry2, gfx.sdlColor)

proc drawRectangle*(gfx: var Graphics, x, y, w, h: float) =
  ## Draw the border of a rectangle with its center at `(x, y)`, and with
  ## width `w` and height `h`.
  proc GPU_Rectangle2(target: ptr GPUTarget,
    rect: GPURect, color: SDLColor)
    {.importc, header: gpuH.}
  GPU_Rectangle2(gfx.screen, gfx.gpuRect(x, y, w, h), gfx.sdlColor)

proc drawRectangleFill*(gfx: var Graphics, x, y, w, h: float) =
  ## Draw a filled rectangle with its center at `(x, y)`, and with width
  ## `w` and height `h`.
  proc GPU_RectangleFilled2(target: ptr GPUTarget,
    rect: GPURect, color: SDLColor)
    {.importc, header: gpuH.}
  GPU_RectangleFilled2(gfx.screen, gfx.gpuRect(x, y, w, h), gfx.sdlColor)

template scope*(gfx: var Graphics, body: typed) =
  ## Create a new graphics scope and run `body` in it. All graphics state
  ## changes in `body` remain within that scope, and after the scope call
  ## the state is restored to the state before the scope call.
  block:
    let oldState = gfx.state
    body
    setState(gfx, oldState)


# Frame

proc beginFrame(gfx: var Graphics) =
  # Update window and renderer size if needed
  let (bestW, bestH) = gfx.selectWindowSize()
  var w, h: cint
  SDL_GetWindowSize(gfx.window, w, h)
  if w != bestW or h != bestH:
    proc SDL_SetWindowSize(window: ptr SDLWindow, w, h: int)
      {.importc, header: sdlH.}
    SDL_SetWindowSize(gfx.window, bestW, bestH)
    GPU_SetWindowResolution(cast[uint16](bestW), cast[uint16](bestH))
    echo "updated window size to (", bestW, ", ", bestH, ")"

  gfx.updateRenderScale()

  gfx.clear(0x28, 0x2a, 0x36)

proc endFrame(gfx: var Graphics) =
  # Flush GPU draw calls
  proc GPU_Flip(target: ptr GPUTarget)
    {.importc, header: gpuH.}
  GPU_Flip(gfx.screen)

  # Destroy textures and programs no one's holding a handle to
  # TODO(nikki): Factor both into a single template used twice?
  block:
    var toDestroy: seq[ref Texture]
    for tex in gfx.texs.mvalues:
      if tex.handleCount == 0:
        toDestroy.add(move(tex))
    for tex in toDestroy:
      gfx.texs.del(tex.path)
  block:
    var toDestroy: seq[ref Program]
    for prog in gfx.progs.mvalues:
      if prog.handleCount == 0:
        toDestroy.add(move(prog))
    for prog in toDestroy:
      gfx.progs.del(prog.path)


template frame*(gfx: var Graphics, body: typed) =
  ## Wrap a single frame of graphics drawing. All drawing procedures
  ## should be called within the body passed to this. This should
  ## generally be called once per iteration of the event loop (see the
  ## `events` module).
  beginFrame(gfx)
  block:
    body
  endFrame(gfx)


# Singleton

proc `=copy`(a: var Graphics, b: Graphics) {.error.}

var gfx*: Graphics ## Maintains the global graphics state, to be passed to
                   ## graphics procedures. The graphics context is setup
                   ## during module initialization, and deinitialized
                   ## automatically on program exit.
