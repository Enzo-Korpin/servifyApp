import request from "supertest";
import { app } from "../app.js";

describe("Auth", () => {
    it("signup authenticates user (token or cookie)", async () => {
        const res = await request(app).post("/api/auth/signup").send({
            fullName: "Karam",
            email: "k@test.com",
            password: "Aa12345678",
            role: "customer",
            lat: 31.95,
            lng: 35.91,
        });

        expect(res.statusCode).toBe(201);

        const setCookie = res.headers["set-cookie"];
        const token = res.body?.token;

        // pass if either is present
        expect(Boolean(setCookie?.length) || Boolean(token)).toBe(true);

        // optional: print once while debugging
        console.log("BODY:", res.body);
        console.log("SET-COOKIE:", setCookie);
    });


    it("login fails with wrong password", async () => {
        await request(app).post("/api/auth/signup").send({
            fullName: "User",
            email: "u@test.com",
            password: "Aa12345678",
            role: "customer",
            lat: 31.95,
            lng: 35.91,
        });

        const res = await request(app).post("/api/auth/login").send({
            email: "u@test.com",
            password: "WrongPass123",
        });

        expect([401, 404]).toContain(res.statusCode); // 401 if user exists, 404 if user missing
    });

});
