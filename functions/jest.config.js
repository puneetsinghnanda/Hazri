/** Two projects:
 *  - `unit`: pure logic, and the Express app's common rules with no database;
 *  - `emulator`: the app and every Function against the Firestore emulator,
 *    skipped when FIRESTORE_EMULATOR_HOST is unset (run them with
 *    `firebase emulators:exec --only firestore "npm --prefix functions run test:emulator"`). */
const base = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  transform: { '^.+\\.ts$': ['ts-jest', { tsconfig: 'tsconfig.json' }] },
};
module.exports = {
  testTimeout: 60000,
  projects: [
    { ...base, displayName: 'unit', testMatch: ['<rootDir>/test/unit/**/*.test.ts'] },
    { ...base, displayName: 'emulator', testMatch: ['<rootDir>/test/emulator/**/*.test.ts'] },
  ],
};
