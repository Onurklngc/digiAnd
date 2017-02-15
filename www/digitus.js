"use strict";
function digitus() {
}

digitus.prototype.initStream = function () {
cordova.exec(null, null, "digitus", "initSDK");
};

digitus.prototype.playStream = function ( success, fail, uid, options) {
    var cameraUID="A02CC-"+uid.replace(/:/g, "").toUpperCase();
    options = options || {};

    cordova.exec(success || null, fail || null, "digitus", "runSDK", [cameraUID, options]);
};

digitus.prototype.stopStream = function () {
cordova.exec(null, null, "digitus", "stopSDK");
};


digitus.install = function () {
    if (!window.plugins) {
        window.plugins = {};
    }
    window.plugins.digitus = new digitus();
    return window.plugins.digitus;
};

cordova.addConstructor(digitus.install);

});
