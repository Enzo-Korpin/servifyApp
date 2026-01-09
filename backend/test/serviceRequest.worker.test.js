import request from "supertest";
import { app } from "../app.js";

describe("ServiceRequest – WORKER role", () => {
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


    it("worker CAN accept request", async () => {
        const res = await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );

        expect(res.statusCode).toBe(200);
        expect(res.body.data.status).toBe("accepted");
    });


    it("worker CAN reject request", async () => {
        const res = await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/reject`
        ).send({ rejectReason: "Busy" });

        expect(res.statusCode).toBe(200);
        expect(res.body.data.status).toBe("rejected");
    });

    it("worker CAN complete request", async () => {
        await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );
        
        const res = await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/complete`
        );
        expect(res.statusCode).toBe(200);
        expect(res.body.data.status).toBe("completed");
    });


    // Edge cases   

    it("worker CANNOT accept same request twice", async () => {
        await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );

        const res = await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );


        expect(res.statusCode).toBe(400);
    });


    it("worker CANNOT accept request that belongs to another worker", async () => {
        const otherWorker = request.agent(app);

        await otherWorker.post("/api/auth/signup").send({
            fullName: "Other Worker",
            email: `other_${Date.now()}@test.com`,
            password: "Aa12345678",
            role: "worker",
            lat: 31.95,
            lng: 35.91,
            yearsOfExperience: 1,
            skills: ["plumbing"],
        });

        const res = await otherWorker.patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );
        expect(res.statusCode).toBe(403);
    });


    it("unauthenticated user CANNOT accept request", async () => {
        const res = await request(app).patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );
        expect(res.statusCode).toBe(401);
    });

    it("worker CANNOT complete request that is not accepted", async () => {
        const res = await workerAgent.patch(
            `/api/request/serviceRequests/${requestId}/complete`
        );
        expect(res.statusCode).toBe(400);
    });
});
