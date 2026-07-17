const os = require('os');
const path = require('path');
const addonStaticImport = require('./addon-static-import');

const platform = os.platform() === 'win32' ? 'win' : os.platform();
const arch = os.arch();
const platform_arch = `${platform}-${arch}`;
const possible_paths = [
  '../build/Release/piper-phonemize.node',
  '../build/Debug/piper-phonemize.node',
  `./node_modules/piper-phonemize-${platform_arch}/piper-phonemize.node`,
  `../piper-phonemize-${platform_arch}/piper-phonemize.node`,
  './piper-phonemize.node',
];

let addon = addonStaticImport;

if (!addon) {
  for (const p of possible_paths) {
    try {
      addon = require(p);
      break;
    } catch (error) {
      // do nothing; try the next option
      ;
    }
  }
}

module.exports = addon;

if (!addon) {
  let addon_path =
      `${process.env.PWD}/node_modules/piper-phonemize-${platform_arch}`;
  const pnpmIndex = __dirname.indexOf(`node_modules${path.sep}.pnpm`);
  if (pnpmIndex !== -1) {
    const parts = __dirname.slice(pnpmIndex).split(path.sep);
    parts.pop();
    addon_path =
        `${process.env.PWD}/${parts.join('/')}/piper-phonemize-${platform_arch}`;
  }

  let msg = `Could not find piper-phonemize-node. Tried\n\n  ${
      possible_paths.join('\n  ')}\n`
  if (os.platform() == 'darwin' &&
      (!process.env.DYLD_LIBRARY_PATH ||
       !process.env.DYLD_LIBRARY_PATH.includes(
           `node_modules/piper-phonemize-${platform_arch}`))) {
    msg +=
        'Please remember to set the following environment variable and try again:\n';

    msg += `export DYLD_LIBRARY_PATH=${addon_path}`;

    msg += ':$DYLD_LIBRARY_PATH\n';
  }

  if (os.platform() == 'linux' &&
      (!process.env.LD_LIBRARY_PATH ||
       !process.env.LD_LIBRARY_PATH.includes(
           `node_modules/piper-phonemize-${platform_arch}`))) {
    msg +=
        'Please remember to set the following environment variable and try again:\n';

    msg += `export LD_LIBRARY_PATH=${addon_path}`;

    msg += ':$LD_LIBRARY_PATH\n';
  }

  throw new Error(msg)
}
