/** Playbook v1.1
 * 
 * This playbook showcases the many ways
 * Autumn can help you tap into the full
 * power of your Mac through automation.
 * 
 * For the most up-to-date playbook, and
 * to discover ideas shared by others or
 * share your own ideas, visit:
 * 
 * https://sephware.com/autumn/playbook
 */




/**
 * Full-featured flexible window manager example in ~40 lines.
 * Experiment and adapt to your preference, or can be used as-is.
 * 
 * Exercise: make it allow for multiple rows instead of a fixed number.
 * 
 * Note: in Autumn, localStorage stores JSON objects, not just strings
 */

const grid = new GridWM();
grid.rows = localStorage.getItem('rows') as number || 2;
grid.cols = localStorage.getItem('cols') as number || 6;

Hotkey.activate(['command', 'control', 'option'], 'h', () => grid.moveLeft());
Hotkey.activate(['command', 'control', 'option'], 'l', () => grid.moveRight());
Hotkey.activate(['command', 'control', 'option'], 'k', () => { grid.shrinkFromBelow(); grid.moveUp() });
Hotkey.activate(['command', 'control', 'option'], 'j', () => { grid.shrinkFromAbove(); grid.moveDown() });

Hotkey.activate(['command', 'shift', 'option'], 'h', () => Window.focusedWindow().focusNext('left'));
Hotkey.activate(['command', 'shift', 'option'], 'l', () => Window.focusedWindow().focusNext('right'));
Hotkey.activate(['command', 'shift', 'option'], 'k', () => Window.focusedWindow().focusNext('up'));
Hotkey.activate(['command', 'shift', 'option'], 'j', () => Window.focusedWindow().focusNext('down'));

Hotkey.activate(['command', 'control', 'option'], 'o', () => grid.growRight());
Hotkey.activate(['command', 'control', 'option'], 'i', () => grid.shrinkFromRight());
Hotkey.activate(['command', 'control', 'option'], 'u', () => grid.fillCurrentColumn());
Hotkey.activate(['command', 'control', 'option'], 'm', () => grid.moveToCellGroup(grid.fullScreenCellGroup()));

Hotkey.activate(['command', 'control', 'option'], 'c', () => Window.focusedWindow().centerOnScreen());

Hotkey.activate(['command', 'control', 'option'], ';', () => grid.align());
Hotkey.activate(['command', 'control', 'option'], "'", () => grid.alignAll());

Hotkey.activate(['command', 'control', 'option'], 'n', () => grid.moveToNextScreen());
Hotkey.activate(['command', 'control', 'option'], 'p', () => grid.moveToPreviousScreen());

Hotkey.activate(['command', 'control', 'option'], '-', () => changeWidthBy(-1));
Hotkey.activate(['command', 'control', 'option'], '=', () => changeWidthBy(+1));

function changeWidthBy(n) {
  grid.cols = Math.max(1, grid.cols + n);
  localStorage.setItem('cols', grid.cols);
  alert(`Grid width is now ${grid.cols}`);
  grid.alignAll();
}

alert(`Running GridWM example, rows = ${grid.rows}, cols = ${grid.cols}`);




/**
 * While [Command + Shift + Fn] are held, window under mouse follows mouse.
 */
Keyboard.onModsChanged = (mods) => {
  if (mods.Command && mods.Shift && mods.Fn) {
    if (!Mouse.onMoved) {
      const win = Window.windowUnderMouse();
      const offset = win.position().minus(Mouse.position());
      Mouse.onMoved = (p) => {
        win.setPosition(p.plus(offset));
      }
    }
  }
  else {
    if (Mouse.onMoved) {
      Mouse.onMoved = null;
    }
  }
};




/**
 * Prevent computer from sleeping while specific app is open.
 */

App.onAppLaunched = (app) => {
  if (app.name === 'Dictionary') {
    console.log(`${app.name} has opened. Preventing sleep.`);
    const allowSleep = Power.preventSleep();
    app.onTermination = () => {
      console.log(`${app.name} has quit. Allowing sleep again.`);
      allowSleep();
    };
  }
}




/**
 * Make the mouse's Y position control the screen's brightness.
 */

Mouse.onMoved = p => {
  let frame = Screen.currentScreen().fullFrame();
  let y = frame.bottomY - p.y - frame.topY;
  let percent = y / frame.height;
  Brightness.setLevel(percent);
};




/**
 * Make all windows dance!
 * Caution: may be dizzying
 */

function dance(win: Window) {
  const f = win.position();
  const w = (Math.random() * 0.6 + 0.4) * 200;
  const h = (Math.random() * 0.6 + 0.4) * 200;
  // const h = w; // this makes it a circle
  const r = 7;
  setInterval(() => {
    const t = new Date().getTime();
    win.setPosition({
      x: f.x + (Math.cos(t / w) * r),
      y: f.y + (Math.sin(t / h) * r),
    });
  }, 50);
}

Window.visibleWindows().forEach(dance);
Window.onWindowOpened = dance;

setTimeout(() => {
  Autumn.stop();
}, 1000 * 5); // stop the Autumn script after 5 seconds




/**
 * Save focused window's position and restore it later.
 * Simplistic demo to illustrate that hotkeys can "interact".
 */

let f: Rect;

Hotkey.activate(['command', 'option', 'control'], 'm', () => {
  f = Window.focusedWindow().frame();
  Window.focusedWindow().maximize();
});

Hotkey.activate(['command', 'option', 'control'], 'r', () => {
  Window.focusedWindow().setFrame(f);
});




/** 
 * Save window positions and restore them later.
 * Uses a list of functions for more fool-proof-ness.
 * Could become the start of an "undo move/resize" implementation.
 */

let restorers: { [id: string]: () => void } = {};

Hotkey.activate(['command', 'option', 'control'], 'm', () => {
  let win = Window.focusedWindow();
  if (!restorers[win.id]) {
    let oldFrame = win.frame();
    restorers[win.id] = () => win.setFrame(oldFrame);
    Window.focusedWindow().maximize();
  }
});

Hotkey.activate(['command', 'option', 'control'], 'r', () => {
  Object.values(restorers).forEach(fn => fn());
  restorers = {};
});




/**
 * Make the window do the wave!
 */

function doTheWave(win: Window) {
  const screenFrame = win.screen().innerFrame();
  const winFrame = win.frame();
  const y = screenFrame.centerY - (winFrame.height / 2);
  for (let x = screenFrame.leftX; x < screenFrame.rightX - winFrame.width; x++) {
    setTimeout(() => {
      win.setPosition({
        x,
        y: y + (Math.cos(x / 50) * 40),
      });
    }, (x * 2));
  }
}

doTheWave(Window.focusedWindow());




/** 
 * Add custom menu items to Autumn's menu bar icon.
 * Note: this requires the menu bar icon to be shown via the Preferences window.
 */

Autumn.setStatusMenuItems([
  { title: 'Reload Autumn', onClick: Autumn.reloadUserScripts },
  { title: '-' },
  { title: 'Maximize window', onClick() { Window.focusedWindow().maximize() } },
  {
    title: 'Unminimize all windows',
    onClick() {
      Window
        .allWindows()
        .filter(win => win.isMinimized)
        .forEach(win => win.unminimize());
    }
  },
]);




/**
 * Show welcome message when computer wakes from sleep
 */

let sleepTime: number;
Power.onSleep = () => {
  const now = new Date();
  sleepTime = now.getTime();
  console.log(`Good night! Sleeping at ${now.toLocaleString()}.`);
};

Power.onWake = () => {
  const now = new Date();
  let time = Math.floor((now.getTime() - sleepTime) / 1000);
  const delay = 7; // seconds
  alert("Good morning!", delay);
  alert(`It's ${now.toLocaleString()}.`, delay);
  alert(`Computer slept for ${hhmmss(time)}.`, delay);
}

function hhmmss(time) {
  const s = time % 60;
  time = Math.floor(time / 60);
  const m = time % 60;
  time = Math.floor(time / 60);
  const h = time;
  return [h, m, s].map(padWithZeroes).join(':');
}

function padWithZeroes(n: number) {
  return n.toString().padStart(2, '0');
}