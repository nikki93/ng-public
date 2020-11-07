mergeInto(LibraryManager.library, {
  JS_isWindowFocused: function () {
    return document.hasFocus();
  },

  JS_getCanvasWidth: function () {
    return document.querySelector('#canvas').getBoundingClientRect().width;
  },
});
