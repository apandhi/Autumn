/**
 * Welcome to Autumn!
 * Here's some sample code to get you started.
 * Click the Play button to try it out!
 */

alert('Running Autumn!');

// Pressing Cmd+Opt+Ctrl+M will maximize the window.
Hotkey.activate(['command', 'option', 'control'], 'm', () => {
  Window.focusedWindow().maximize();
});

// Modifier keys are strongly typed to prevent typos
const cmdOptCtrl: ModString[] = ['command', 'option', 'control']

// Pressing Cmd+Opt+Ctrl+C centers the window on screen.
// Adjust the percent to your liking.
Hotkey.activate(cmdOptCtrl, 'c', () => {
  const percent = 0.65;
  Window.focusedWindow().moveToPercentOfScreen({
    x: (1 - percent) / 2,
    y: (1 - percent) / 2,
    width: percent,
    height: percent,
  })
});

// Let's make a function to make our code shorter.
function moveToUnit(x, y, width, height) {
  Window.focusedWindow().moveToPercentOfScreen({
    x, y, width, height
  });
}

// Try pressing Cmd+Opt+Ctrl and arrow keys
Hotkey.activate(cmdOptCtrl, 'up',
  () => { moveToUnit(0, 0, 1, 0.5) });
Hotkey.activate(cmdOptCtrl, 'down',
  () => { moveToUnit(0, 0.5, 1, 0.5) });
Hotkey.activate(cmdOptCtrl, 'left',
  () => { moveToUnit(0, 0, 0.5, 1) });
Hotkey.activate(cmdOptCtrl, 'right',
  () => { moveToUnit(0.5, 0, 0.5, 1) });

// Click the Playbook button for more ideas.