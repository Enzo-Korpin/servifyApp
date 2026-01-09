process.env.NODE_ENV ||= "test";
process.env.JWT_SECRET ||= "test_jwt_secret";

import { connectTestDB, clearTestDB, closeTestDB } from "./db.js";


beforeAll(async () => {
  await connectTestDB();
});

afterEach(async () => {
  await clearTestDB();
});

afterAll(async () => {
  await closeTestDB();
});
