mergeInto(LibraryManager.library, {
  //
  // events
  //

  JS_isWindowFocused: function () {
    return document.hasFocus();
  },

  //
  // graphics
  //

  JS_getCanvasWidth: function () {
    return document.querySelector('#canvas').getBoundingClientRect().width;
  },

  //
  // uis
  //

  JS_uiElemOpenStart: function (tag) {
    IncrementalDOM.elementOpenStart(UTF8ToString(tag));
  },
  JS_uiElemOpenStartKeyInt: function (tag, key) {
    IncrementalDOM.elementOpenStart(UTF8ToString(tag), key);
  },
  JS_uiElemOpenStartKeyStr: function (tag, key) {
    IncrementalDOM.elementOpenStart(UTF8ToString(tag), UTF8ToString(key));
  },

  JS_uiElemOpenEnd: function () {
    IncrementalDOM.elementOpenEnd();
  },

  JS_uiElemClose: function (tag) {
    IncrementalDOM.elementClose(UTF8ToString(tag));
  },

  JS_uiAttrInt: function (name, value) {
    IncrementalDOM.attr(UTF8ToString(name), value);
  },
  JS_uiAttrFloat: function (name, value) {
    IncrementalDOM.attr(UTF8ToString(name), value);
  },
  JS_uiAttrBool: function (name, value) {
    if (value) {
      IncrementalDOM.attr(UTF8ToString(name), '');
    }
  },
  JS_uiAttrStr: function (name, value) {
    IncrementalDOM.attr(UTF8ToString(name), UTF8ToString(value));
  },
  JS_uiAttrClass: function (value) {
    IncrementalDOM.attr('class', UTF8ToString(value));
  },

  JS_uiText: function (value) {
    IncrementalDOM.text(UTF8ToString(value));
  },

  JS_uiEventCount: function (type) {
    const typeStr = UTF8ToString(type);
    const target = IncrementalDOM.currentElement();
    if (!target.__UIHandlerRegistered) {
      target.addEventListener(typeStr, window.UI.eventHandler);
      target.__UIHandlerRegistered = true;
    }
    const counts = window.UI.eventCounts.get(target);
    if (counts === undefined) {
      return 0;
    }
    const count = counts[typeStr];
    if (count === undefined) {
      return 0;
    }
    return count;
  },
  JS_uiClearEventCounts: function () {
    window.UI.eventCounts = new WeakMap();
  },

  JS_uiValue: function () {
    const str = IncrementalDOM.currentElement().value;
    return allocate(intArrayFromString(str), 'i8', ALLOC_NORMAL);
  },

  JS_uiPatch: function (id) {
    const el = document.getElementById(UTF8ToString(id));
    if (el) {
      IncrementalDOM.patch(el, () => {
        Module._JS_uiCallPatchProc();
      });
    }
  },
});
