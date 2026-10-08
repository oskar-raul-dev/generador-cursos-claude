const assert = require('assert');

// Node 10 no necesita un test runner para comprobar que el runtime vive.
assert.strictEqual(1 + 1, 2);

console.log('✅ smoke test OK');
