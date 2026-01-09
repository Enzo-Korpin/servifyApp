import request from "supertest";
import { app } from "../app.js";

describe("ServiceRequest – CUSTOMER role", () => {
    let customerAgent;
    let workerAgent;
    let workerId;
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
            yearsOfExperience: 1,
            skills: ["plumbing"],
        });

        workerId = wRes.body.user._id;

        // create request as customer
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


    it("customer CAN create service request", async () => {
        expect(requestId).toBeDefined();
    });


    it("customer CAN cancel pending request", async () => {
        const res = await customerAgent
        .patch(`/api/request/serviceRequests/${requestId}/cancel`)
        .send({ cancelReason: "Change of plans" });

        
        expect(res.statusCode).toBe(200);
        expect(res.body.data.status).toBe("cancelled");
    });


    // Edge cases 

    it("customer CANNOT accept request (wrong role)", async () => {
        const res = await customerAgent.patch(
            `/api/request/serviceRequests/${requestId}/accept`
        );
        expect(res.statusCode).toBe(403);
    });

    it("customer CANNOT create request without workerId", async () => {
        const res = await customerAgent
            .post("/api/request/serviceRequests")
            .send({
                message: "No worker",
                location: { lat: 31.95, lng: 35.91 },
            });
        expect(res.statusCode).toBe(400);
    });

    it("customer CANNOT cancel after request is accepted", async () => {
        await workerAgent.patch(`/api/request/serviceRequests/${requestId}/accept`);

        const res = await customerAgent
        .patch(`/api/request/serviceRequests/${requestId}/cancel`)
        .send({ cancelReason: "Too late" });
        expect(res.statusCode).toBe(400);
    });
});
