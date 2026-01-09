export default {
  testEnvironment: "node",
  rootDir: ".",
  roots: ["<rootDir>/backend/test"],
  setupFilesAfterEnv: ["<rootDir>/backend/test/setup/jest.setup.js"],
  testTimeout: 60000,
  transform: {},
};
