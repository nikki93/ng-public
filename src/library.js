mergeInto(LibraryManager.library, {
  JS_isWindowFocused: function () {
    return document.hasFocus();
  },
});
