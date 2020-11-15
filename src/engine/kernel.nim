import macros, sets


const enttH = "\"precomp.h\""

type
  Entity* {.importcpp: "entt::entity", header: enttH.} = object

  Registry {.importcpp: "entt::registry", header: enttH.} = object

  Kernel = object
    reg: Registry

    typeMetas: seq[TypeMeta]

  TypeMeta = object
    name: string
    add: proc(ent: Entity): pointer
    remove: proc(ent: Entity)
    get: proc(ent: Entity): pointer


# Meta compile-time vars

var typeIdents {.compileTime.}: seq[NimNode]

var typeNames {.compileTime.}: HashSet[string]


# Ids

let null* {.importcpp: "kernel_null".}: Entity
{.emit: "entt::entity kernel_null = entt::null;".}

proc `==`*(a: Entity, b: Entity): bool {.importcpp: "# == #".}

proc toIntegral*(ent: Entity): uint32
  {.importcpp: "entt::to_integral(#)".}

proc toEntity*(value: uint32): Entity
  {.importcpp: "entt::entity(#)".}

proc `$`*(ent: Entity): string {.inline.} =
  "Entity(" & $ent.toIntegral & ")"


# Create / destroy

proc create*(ker: var Kernel): Entity {.inline.} =
  proc create(reg: var Registry): Entity
    {.importcpp.}
  ker.reg.create()

proc destroy*(ker: var Kernel, ent: Entity) {.inline.} =
  proc destroy(reg: var Registry, ent: Entity)
    {.importcpp.}
  for typeMeta in ker.typeMetas:
    typeMeta.remove(ent)
  ker.reg.destroy(ent)


# Get

proc get*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
  proc tryGet[T](reg: var Registry, ent: Entity): ptr T
    {.importcpp: "#.try_get<'*0>(#)".}
  ker.reg.tryGet[:T](ent)


# Add / remove

proc add*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
  static:
    if not typeNames.contains($T):
      error("type '" & $T & "' must be registered with ng.")
  proc emplace[T](reg: var Registry, ent: Entity): ptr T
    {.importcpp: "&#.emplace<'*0>(#)".}
  result = ker.reg.emplace[:T](ent)
  zeroMem(result, sizeof(T))

proc remove*(ker: var Kernel, T: typedesc, ent: Entity) {.inline.} =
  proc remove[T](reg: var Registry, ent: Entity, _: ptr T)
    {.importcpp: "#.remove<'*3>(#)".}
  var got = ker.get(T, ent)
  if got != nil:
    `=destroy`(got[])
    ker.reg.remove[:T](ent, nil)

#proc ensure*(ker: var Kernel, T: typedesc, ent: Entity): ptr T {.inline.} =
#  result = ker.get(T, ent)
#  if result == nil:
#    result = ker.add(T, ent)


# Queries

const useLambdaEach = false

iterator each*(ker: var Kernel): Entity =
  proc data(reg: var Registry): ptr Entity
    {.importcpp: "(entt::entity *) #.data()".}
  proc size(reg: var Registry): int
    {.importcpp: "size".}
  proc valid(reg: var Registry, ent: Entity): bool
    {.importcpp: "valid".}
  let dat = ker.reg.data()
  let sz = ker.reg.size()
  for i in 0..<sz:
    var ent: Entity
    {.emit: [ent, " = ", dat, "[", i, "];"].}
    if ker.reg.valid(ent):
      yield ent

iterator each*(ker: var Kernel, T1: typedesc): (Entity, ptr T1) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ">()",
      ".each([&](auto pe_, auto &pc1_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_] : ",
      ker.reg, ".view<", T1, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  yield(e, c1)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}

iterator each*(ker: var Kernel, T1, T2: typedesc): (Entity, ptr T1, ptr T2) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ">()",
      ".each([&](auto pe_, auto &pc1_, auto &pc2_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_] : ",
      ker.reg, ".view<", T1, ", ", T2, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  var c2: ptr T2
  {.emit: [c2, " = &pc2_;"].}
  yield(e, c1, c2)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}

iterator each*(ker: var Kernel, T1, T2, T3: typedesc):
    (Entity, ptr T1, ptr T2, ptr T3) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ", ", T3, ">()",
      ".each([&](auto pe_, auto &pc1_, auto &pc2_, auto &pc3_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_, pc3_] : ",
      ker.reg, ".view<", T1, ", ", T2, ", ", T3, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  var c2: ptr T2
  {.emit: [c2, " = &pc2_;"].}
  var c3: ptr T3
  {.emit: [c3, " = &pc3_;"].}
  yield(e, c1, c2, c3)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}

iterator each*(ker: var Kernel, T1, T2, T3, T4: typedesc):
    (Entity, ptr T1, ptr T2, ptr T3, ptr T4) =
  when useLambdaEach:
    {.emit: [ker.reg, ".view<", T1, ", ", T2, ", ", T3, ", ", T4, ">()",
      ".each([&](auto pe_, auto &pc1_, auto &pc2_, auto &pc3_, auto &pc4_) {"].}
  else:
    {.emit: ["for (auto [pe_, pc1_, pc2_, pc3_, pc4_] : ",
      ker.reg, ".view<", T1, ", ", T2, ", ", T3, ", ", T4, ">().proxy()) {"].}
  var e: Entity
  {.emit: [e, " = pe_;"].}
  var c1: ptr T1
  {.emit: [c1, " = &pc1_;"].}
  var c2: ptr T2
  {.emit: [c2, " = &pc2_;"].}
  var c3: ptr T3
  {.emit: [c3, " = &pc3_;"].}
  var c4: ptr T4
  {.emit: [c4, " = &pc4_;"].}
  yield(e, c1, c2, c3, c4)
  when useLambdaEach:
    {.emit: "});".}
  else:
    {.emit: "}".}


# Clear

proc clear*(ker: var Kernel) {.inline.} =
  for ent in ker.each():
    ker.destroy(ent)

proc clear*[T](ker: var Kernel, _: typedesc[T]) {.inline.} =
  for ent, _ in ker.each(T):
    ker.remove(T, ent)


# Sort

proc isort*[T](
  ker: var Kernel,
  _: typedesc[T],
  compare: proc (a: ptr T, b: ptr T): bool {.cdecl.},
) {.inline.} =
  {.emit: [ker.reg, ".sort<", T, ">([&](const auto &a, const auto &b) {",
    "return ", compare, "(const_cast<", T, "*>(&a), const_cast<", T, "*>(&b));",
  "}, entt::insertion_sort{});"].}


# Init / deinit

proc init*(ker: var Kernel) =
  echo "initialized kernel"

proc deinit*(ker: var Kernel) =
  ker.clear()
  echo "deinitialized kernel"


# Singleton

proc `=copy`(a: var Kernel, b: Kernel) {.error.}

var ker*: Kernel


# Meta

macro ng*(body: untyped) =
  let ident = body[0][0]
  ident.expectKind nnkIdent
  typeIdents.add(ident)
  typeNames.incl($ident)
  body

proc registerTypeMeta[T](name: string) =
  var tm: TypeMeta
  tm.name = name
  tm.add = proc(ent: Entity): pointer =
    ker.add(T, ent)
  tm.remove = proc(ent: Entity) =
    ker.remove(T, ent)
  tm.get = proc(ent: Entity): pointer =
    ker.get(T, ent)
  ker.typeMetas.add(tm)

macro initMeta*() =
  ## Initializes the ng meta system. This macro must be invoked after all
  ## registered types and their hooks have been defined, and before meta
  ## information is read.
  result = newStmtList()
  for typeIdent in typeIdents:
    let name = $typeIdent
    result.add quote do:
      registerTypeMeta[`typeIdent`](`name`)
  result = newBlockStmt(result)