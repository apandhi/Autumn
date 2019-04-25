// THIS FILE IS NOT PART OF THE DISTRIBUTED MONACO EDITOR
// DON'T DELETE IT WHEN UPDATING!!!

// it has to be loaded after monaco-editor/loader.js

// Set the correct root path
require.config({ paths: { 'vs': 'vs' }});

// Allow localisation

// All languages in monaco-editor
var availableLanguages = ['de', 'fr', 'es', 'it', 'ja', 'ru', 'ko', 'zh-tw', 'zh-cn'];
// find the best match
function findLanguage() {
    if (navigator.languages && Array.isArray(navigator.languages)) {
        return navigator.languages.find(function (lang) {return availableLanguages.indexOf(lang) > -1});
    }
    var lang = navigator.language || navigator.userLanguage;
    if (typeof lang === 'string') {
        // first try the long version
        if (availableLanguages.indexOf(lang) > -1) return lang;
        // then the short one
        lang = lang.substr(0, 2);
        if (availableLanguages.indexOf(lang) > -1) return lang;
    }
}

var language = findLanguage();
// if we have a match, configure the editor
if (language != null) {
    require.config({
        'vs/nls': {
            availableLanguages: {
                '*': language
            }
        }
    });
}

// And load the editor itself
require(['vs/editor/editor.main'], function () { });
