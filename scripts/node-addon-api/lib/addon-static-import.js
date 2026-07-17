const os = require('os');

let addon = null;

const platform = os.platform() === 'win32' ? 'win' : os.platform();
const arch = os.arch();

try {
  if (arch === 'x64') {
    if (platform === 'win') {
      addon = require('../piper-phonemize-win-x64/piper-phonemize.node')
    } else if (platform === 'darwin') {
      addon = require('../piper-phonemize-darwin-x64/piper-phonemize.node')
    } else if (platform === 'linux') {
      addon = require('../piper-phonemize-linux-x64/piper-phonemize.node')
    }
  } else if (arch === 'arm64') {
    if (platform === 'darwin') {
      addon = require('../piper-phonemize-darwin-arm64/piper-phonemize.node')
    } else if (platform === 'linux') {
      addon = require('../piper-phonemize-linux-arm64/piper-phonemize.node')
    }
  } else if (arch === 'ia32') {
    if (platform === 'win') {
      addon = require('../piper-phonemize-win-ia32/piper-phonemize.node')
    }
  }
} catch (error) {
  //
}

if (!addon) {
  try {
    if (arch === 'x64') {
      if (platform === 'win') {
        addon = require('./node_modules/piper-phonemize-win-x64/piper-phonemize.node')
      } else if (platform === 'darwin') {
        addon = require('./node_modules/piper-phonemize-darwin-x64/piper-phonemize.node')
      } else if (platform === 'linux') {
        addon = require('./node_modules/piper-phonemize-linux-x64/piper-phonemize.node')
      }
    } else if (arch === 'arm64') {
      if (platform === 'darwin') {
        addon = require('./node_modules/piper-phonemize-darwin-arm64/piper-phonemize.node')
      } else if (platform === 'linux') {
        addon = require('./node_modules/piper-phonemize-linux-arm64/piper-phonemize.node')
      }
    } else if (arch === 'ia32') {
      if (platform === 'win') {
        addon = require('./node_modules/piper-phonemize-win-ia32/piper-phonemize.node')
      }
    }
  } catch (error) {
    //
  }
}

module.exports = addon;
