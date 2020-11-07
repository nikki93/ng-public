mergeInto(LibraryManager.library, {
  sayHello: function (name) {
    console.log(`hello there, ${UTF8ToString(name)}!`);
  },
});
