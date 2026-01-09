import request from "supertest";
import { app } from "../app.js";

describe("Feedback", () => {
    let customerAgent;
    let workerAgent;
    let requestId;

    beforeEach(async () => {
        customerAgent = request.agent(app);
        workerAgent = request.agent(app);

        // signup customer
        await customerAgent.post("/api/auth/signup").send({
            fullName: "Customer",
            email: `customer_${Date.now()}@test.com`,
            password: "Aa12345678",
            role: "customer",
            lat: 31.95,
            lng: 35.91,
        });

        // signup worker
        const wRes = await workerAgent.post("/api/auth/signup").send({
            fullName: "Worker",
            email: `worker_${Date.now()}@test.com`,
            password: "Aa12345678",
            role: "worker",
            lat: 31.95,
            lng: 35.91,
            yearsOfExperience: 2,
            skills: ["plumbing"],
        });

        const workerId = wRes.body.user._id;

        // create request
        const created = await customerAgent
            .post("/api/request/serviceRequests")
            .send({
                workerId,
                message: "Fix sink",
                addressText: "Amman",
                location: { lat: 31.95, lng: 35.91 },
            });

        requestId = created.body.data._id;
    });


    it("customer CAN feedback after completion", async () => {
        const acc = await workerAgent.patch(`/api/request/serviceRequests/${requestId}/accept`);
        expect(acc.statusCode).toBe(200);

        const comp = await workerAgent.patch(`/api/request/serviceRequests/${requestId}/complete`);
        expect(comp.statusCode).toBe(200);

        const res = await customerAgent
            .post(`/api/request/serviceRequests/${requestId}/feedback`)
            .send({ rating: 5, comment: "Great job!" });

        // Debug
        console.log("FEEDBACK:", res.statusCode, res.text);

        expect(res.statusCode).toBe(201);
        expect(res.body.feedback.rating).toBe(5);
    });



    // Edge cases   

    it("customer CANNOT feedback before completion", async () => {
        const res = await customerAgent
            .post(`/api/request/serviceRequests/${requestId}/feedback`)
            .send({
                rating: 4,
                comment: "Good job!",
            });
        console.log("NEG FEEDBACK:", res.statusCode, res.text);
        expect(res.statusCode).toBe(400);
    });
});
