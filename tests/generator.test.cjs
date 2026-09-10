const assert = require('node:assert/strict');
const fs = require('node:fs');
const test = require('node:test');
const vm = require('node:vm');

const source = fs.readFileSync(require('node:path').join(__dirname, '..', 'Generator.js'), 'utf8');
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: 'Generator.js' });

function mod97(value) {
  return BigInt(value) % 97n;
}

function ibanDigits(raw) {
  const rotated = raw.slice(4) + raw.slice(0, 4);
  return [...rotated].map((char) => /[A-Z]/.test(char) ? String(char.charCodeAt(0) - 55) : char).join('');
}

function bsnChecksum(raw) {
  const weights = [9, 8, 7, 6, 5, 4, 3, 2, -1];
  return [...raw].reduce((sum, digit, index) => sum + Number(digit) * weights[index], 0);
}

test('exports the supported country catalog', () => {
  assert.deepEqual(JSON.parse(JSON.stringify(sandbox.countries)), [
    { code: 'BE', name: 'Belgium' },
    { code: 'NL', name: 'Netherlands' },
    { code: 'DE', name: 'Germany' },
    { code: 'FR', name: 'France' },
  ]);
});

test('generates valid IBAN structure and MOD97 checksums for every country', () => {
  const patterns = {
    BE: /^BE\d{2}\d{3}\d{7}\d{2}$/,
    NL: /^NL\d{2}[A-Z]{4}\d{10}$/,
    DE: /^DE\d{2}\d{18}$/,
    FR: /^FR\d{2}\d{23}$/,
  };
  for (const code of Object.keys(patterns)) {
    for (let i = 0; i < 100; i += 1) {
      const result = sandbox.generateIban(code);
      assert.equal(result.country, code);
      assert.match(result.raw, patterns[code]);
      assert.equal(mod97(ibanDigits(result.raw)), 1n);
      assert.equal(result.formatted.replaceAll(' ', ''), result.raw);
    }
  }
});

test('uses the Belgian domestic modulo-97 check and French RIB key', () => {
  for (let i = 0; i < 100; i += 1) {
    const be = sandbox.generateIban('BE').raw;
    assert.equal(Number(mod97(be.slice(4, 14))) || 97, Number(be.slice(14)));

    const fr = sandbox.generateIban('FR').raw;
    const bank = Number(fr.slice(4, 9));
    const branch = Number(fr.slice(9, 14));
    const account = Number(fr.slice(14, 25));
    const expected = 97 - ((89 * bank + 15 * branch + 3 * account) % 97);
    assert.equal(Number(fr.slice(25)), expected);
  }
});

test('Belgian domestic check uses 97 when the remainder is zero', () => {
  const zeroRandom = { Math: Object.create(Math) };
  zeroRandom.Math.random = () => 0;
  vm.runInNewContext(source, zeroRandom);
  const raw = zeroRandom.generateIban('BE').raw;
  assert.equal(raw.slice(14), '97');
  assert.equal(mod97(ibanDigits(raw)), 1n);
});

test('generates 1940 through today INSS values with valid parity and checksums', () => {
  const now = new Date();
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  for (let i = 0; i < 2000; i += 1) {
    const result = sandbox.generateInss();
    assert.match(result.raw, /^\d{11}$/);
    assert.match(result.formatted, /^\d{2}\.\d{2}\.\d{2}-\d{3}-\d{2}$/);
    assert.equal(result.formatted.replace(/[.\-]/g, ''), result.raw);
    assert.match(result.birthDate, /^\d{4}-\d{2}-\d{2}$/);
    const date = new Date(`${result.birthDate}T00:00:00Z`);
    assert.ok(date >= new Date('1940-01-01T00:00:00Z'));
    assert.ok(date <= today);
    const serial = Number(result.raw.slice(6, 9));
    assert.ok(serial >= 1 && serial <= 998);
    assert.equal(serial % 2, result.sex === 'male' ? 1 : 0);
    const year = Number(result.birthDate.slice(0, 4));
    const input = `${year >= 2000 ? '2' : ''}${result.raw.slice(0, 9)}`;
    assert.equal(BigInt(result.raw.slice(9)), 97n - (BigInt(input) % 97n));
  }
});

test('honors fixed INSS date and sex, including the 2000 checksum boundary', () => {
  const before = sandbox.generateInss({ birthDate: '1999-12-31', sex: 'male' });
  const after = sandbox.generateInss({ birthDate: '2000-01-01', sex: 'female' });
  assert.equal(before.birthDate, '1999-12-31');
  assert.equal(before.sex, 'male');
  assert.equal(Number(before.raw.slice(6, 9)) % 2, 1);
  assert.equal(after.birthDate, '2000-01-01');
  assert.equal(after.sex, 'female');
  assert.equal(Number(after.raw.slice(6, 9)) % 2, 0);
  assert.equal(BigInt(before.raw.slice(9)), 97n - (BigInt(before.raw.slice(0, 9)) % 97n));
  assert.equal(BigInt(after.raw.slice(9)), 97n - (BigInt(`2${after.raw.slice(0, 9)}`) % 97n));
});

test('generates randomized nine-digit BSNs with valid eleven checksums', () => {
  for (let i = 0; i < 2000; i += 1) {
    const result = sandbox.generateBsn();
    assert.match(result.raw, /^\d{9}$/);
    assert.equal(result.formatted, result.raw);
    assert.notEqual(result.raw, '000000000');
    assert.equal(bsnChecksum(result.raw) % 11, 0);
  }
});

test('preserves leading zeroes in BSNs', () => {
  const leadingZeroRandom = { Math: Object.create(Math) };
  const values = [0, 0, 0, 0, 0, 0, 0, 0.1];
  leadingZeroRandom.Math.random = () => values.shift() || 0;
  vm.runInNewContext(source, leadingZeroRandom);
  const result = leadingZeroRandom.generateBsn();
  assert.equal(result.raw, '000000012');
  assert.equal(result.formatted, result.raw);
  assert.equal(bsnChecksum(result.raw) % 11, 0);
});

test('rejects invalid BSN prefixes without modifying the next valid candidate', () => {
  // Includes remainder 10 with first digits 6 and 9, plus the all-zero case.
  for (const invalidPrefix of ['60000000', '90000003', '00000000']) {
    const controlled = { Math: Object.create(Math) };
    const digits = [...(invalidPrefix + '01234567')];
    controlled.Math.random = () => {
      assert.ok(digits.length, 'must accept the next valid prefix');
      return Number(digits.shift()) / 10;
    };
    vm.runInNewContext(source, controlled);
    const result = controlled.generateBsn();
    assert.equal(result.raw, '012345672');
    assert.equal(bsnChecksum(result.raw) % 11, 0);
    assert.equal(digits.length, 0);
  }
});

test('fails promptly when the random source only produces invalid BSNs', () => {
  const controlled = { Math: Object.create(Math) };
  let calls = 0;
  controlled.Math.random = () => { calls += 1; return 0; };
  vm.runInNewContext(source, controlled);
  assert.throws(() => controlled.generateBsn(), /Unable to generate a BSN/);
  assert.equal(calls, 800);
});

test('rejects malformed, impossible, out-of-range, and unsupported inputs', () => {
  for (const value of ['2000-2-01', '2000-02-30', '1939-12-31', '2099-01-01', '', 20000101]) {
    assert.throws(() => sandbox.generateInss({ birthDate: value }), /birthDate/);
  }
  for (const value of ['x', 'MALE', 'other']) {
    assert.throws(() => sandbox.generateInss({ sex: value }), /sex/);
  }
  assert.throws(() => sandbox.generateInss(null), /options/);
  assert.throws(() => sandbox.generateInss({ nope: true }), /option/);
  for (const value of ['', 'BE1', 'XX', 42, null]) {
    assert.throws(() => sandbox.generateIban(value), /country/);
  }
});
