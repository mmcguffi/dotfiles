// This script takes an iTerm Color Profile as an argument and translates it for use with Visual Studio Code's built-in terminal.
// 
// usage: `node iterm-colors-to-vscode.js [path-to-iterm-profile.json]
// 
// To export an iTerm Color Profile:
//   1) Open iTerm
//   2) Go to Preferences -> Profiles -> Colors
//   3) Other Actions -> Save Profile as JSON
// 
// To generate the applicable color settings and use them in VS Code:
//  1) Run this script from the command line: `node iterm-colors-to-vscode.js [path-to-iterm-profile.json]
//  2) In VS Code, Go to Preferences -> Settings -> Workbench -> Appearance -> Color Customizations -> Edit in settings.json
//  3) Copy and paste the output from the script under `"workbench.colorCustomizations"`
// 
// This script was adapted by Matt Decuir on 2020-04-12.
// Original source: https://gist.github.com/2xAA/bd01638dc9ca46c590fda06c4ef0cc5a
// 

const fs = require('fs');

const mapping = {
  'terminal.background': 'Background Color',
  'terminal.foreground': 'Foreground Color',
  'terminalCursor.background': 'Cursor Text Color',
  'terminalCursor.foreground': 'Cursor Color',
  'terminal.ansiBlack': 'Ansi 0 Color',
  'terminal.ansiBlue': 'Ansi 4 Color',
  'terminal.ansiBrightBlack': 'Ansi 8 Color',
  'terminal.ansiBrightBlue': 'Ansi 12 Color',
  'terminal.ansiBrightCyan': 'Ansi 14 Color',
  'terminal.ansiBrightGreen': 'Ansi 10 Color',
  'terminal.ansiBrightMagenta': 'Ansi 13 Color',
  'terminal.ansiBrightRed': 'Ansi 9 Color',
  'terminal.ansiBrightWhite': 'Ansi 15 Color',
  'terminal.ansiBrightYellow': 'Ansi 11 Color',
  'terminal.ansiCyan': 'Ansi 6 Color',
  'terminal.ansiGreen': 'Ansi 2 Color',
  'terminal.ansiMagenta': 'Ansi 5 Color',
  'terminal.ansiRed': 'Ansi 1 Color',
  'terminal.ansiWhite': 'Ansi 7 Color',
  'terminal.ansiYellow': 'Ansi 3 Color',
  'terminal.selectionBackground': 'Selection Color'
};

const componentToHex = (c, a = 0) => {
  return (Math.floor(c * 255 + (c === 1 ? 0 : a))).toString(16);
};

if (process.argv.length === 3) {
  try {
    const fileName = process.argv[2];
    const rawData = fs.readFileSync(fileName);
    const jsonData = JSON.parse(rawData);

    const convertedValues = Object.keys(mapping).reduce((results, vsCodeKey) => {
      const itermKey = mapping[vsCodeKey];
      const values = jsonData[itermKey];
      if (!values) {
        console.log(`Key ${itermKey} not found in JSON data.`);
        return results;
      }
      const red = componentToHex(values['Red Component'], 1);
      const green = componentToHex(values['Green Component'], 1);
      const blue = componentToHex(values['Blue Component']);
      const vsCodeValue = `#${red}${green}${blue}`;

      results[vsCodeKey] = vsCodeValue;
      return results;
    }, {});

    console.log(`
      "workbench.colorCustomizations": {
        ${Object.keys(convertedValues).map(key => (
          `"${key}": "${convertedValues[key]}"`
        )).join(',\n\t')}
      }
    `);
  } catch (error) {
    console.log(error);
  }
} else {
  console.log('Please pass a json file as an argument.');
  console.log('usage: `node iterm-colors-to-vscode.js [path-to-iterm-profile.json]`');
}