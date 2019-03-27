function __inspectObject(o, seen) {
  if (seen.indexOf(o) !== -1) return { type: 'recursive' };
  seen.push(o);

  if (o === null) return { type: 'null' };

  const result = { type: 'object', entries: [] };
  if (o instanceof Array) {
    result.isArray = true;
    result.len = o.length;
  }
  for (const key in o) {
    result.entries.push({ key, value: __inspect(o[key], seen) });
  }
  if (result.len) {
    result.entries.push({ key: 'length', value: __inspect(result.len, seen) });
  }
  return result;
}

function __inspect(o, seen) {
  switch (typeof o) {
    case 'function': return { type: 'function' };
    case 'undefined': return { type: 'undefined' };
    case 'boolean': return { type: 'boolean', value: o };
    case 'number': return { type: 'number', value: isNaN(o) ? "NaN" : !isFinite(o) ? "Infinity" : o };
    case 'string': return { type: 'string', value: o };
    case 'symbol': return { type: 'symbol', value: o.toString() };
    case 'object': return __inspectObject(o, seen);
  }
}

function _inspect(o) {
  const result = __inspect(o, []);
  return JSON.stringify(result);
}

console.log = (...args) => {
  if (args.length === 1) {
    args = args[0];
    if (typeof args === 'string') {
      _print(JSON.stringify({ type: 'print', value: args }));
      return;
    }
  }
  _print(_inspect(args));
};

function _fixModules(global, docs) {
  docs = JSON.parse(docs);
  docs.forEach(group => {
    group.mods.forEach(({ name: className, groups }) => {
      const cls = global[className];
      if (cls === undefined) return;

      groups.forEach(({ methods }) => {
        methods.forEach(({ name }) => {
          const static = name.startsWith('static ');
          name = static ?
            name.match(/static (\w+)/)[1] :
            name.match(/(\w+)/)[1];

          if (cls.hasOwnProperty(name)) {
            Object.defineProperty(cls, name, { enumerable: true });
          }
          else if (cls.prototype && cls.prototype.hasOwnProperty(name)) {
            Object.defineProperty(cls.prototype, name, { enumerable: true });
          }
        });
      });
    });
  });
}

const _localStorageGetFromBlob = () => {
  const blob = _localStorageGet();
  return blob === undefined ? {} : JSON.parse(blob);
};

class LocalStorage {
  constructor() {
    return new Proxy(this, this);
  }
  get(target, prop) {
    if (prop in target) return target[prop];
    let cake = _localStorageGetFromBlob();
    return prop in cake ? cake[prop] : undefined;
  }
  getItem(prop) {
    let cake = _localStorageGetFromBlob();
    return prop in cake ? cake[prop] : null;
  }
  set(target, prop, val) {
    if (prop in target) throw new Error(`Can't override localStorage property "${prop}".`);
    this.setItem(prop, val);
  }
  setItem(prop, val) {
    let cake = _localStorageGetFromBlob();
    cake[prop] = val;
    _localStorageSet(JSON.stringify(cake));
  }
  get length() {
    return Object.keys(_localStorageGetFromBlob()).length;
  }
  clear() {
    _localStorageSet(null);
  }
  removeItem(prop) {
    let cake = _localStorageGetFromBlob();
    delete cake[prop];
    _localStorageSet(JSON.stringify(cake));
  }
}

localStorage = new LocalStorage();