'use strict';
const Cp = require('child_process');
const Path = require('path');
const Barrier = require('cb-barrier');
const Code = require('code');
const Lab = require('lab');

// Test shortcuts
const lab = exports.lab = Lab.script();
const { describe, it } = lab;
const { expect, fail } = Code;


describe('TSG Console', () => {
  it('successfully starts the server', () => {
    const barrier = new Barrier();
    const options = {
      env: {
        // Minimum environment needed for the server to start.
        COOKIE_PASSWORD: 'SVAbtKJolw3E3ETVJFZwI42X8khI2oWWUTyS',
        COOKIE_SECURE: 0,
        COOKIE_HTTP_ONLY: 1,
        SDC_ACCOUNT: 'test',
        SDC_URL: 'https://us-sw-1.api.joyentcloud.com',
        SDC_KEY_PATH: Path.join(__dirname, 'fixtures', 'id_rsa'),
        SSO_URL: 'https://sso.joyent.com/login',
        TSG_URL: 'https://us-sw-1.api.joyentcloud.com'
      }
    };
    const child = Cp.spawn(process.execPath,
      [Path.resolve(__dirname, '..', 'server.js')], options);
    let stdout = '';

    child.stdout.setEncoding('utf8');
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', fail);

    child.stdout.on('data', (data) => {
      stdout += data;
      if (/server started/.test(stdout)) {
        child.kill();
        expect(child.killed).to.equal(true);
        barrier.pass();
      }
    });

    return barrier;
  });
});
