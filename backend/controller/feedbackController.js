import ServiceRequest from "../models/serviceRequest.js";
import WorkerProfile from "../models/workerProfile.js";
import Feedback from "../models/feedback.js";
import mongoose from "mongoose";
export const submitFeedback = async (req, res) => {
    const session = await mongoose.startSession();
    const safeAbort = async () => {
        try {
            await session.abortTransaction();
        } catch { }
    };

    try {
        const { requestId } = req.params;
        const { rating, comment } = req.body;
        const customerId = req.user._id;

        if (req.user.currentRole !== "customer") {
            return res.status(403).json({ message: "Must be Customer" });
        }

        const ratingX2 = rating * 2;
        session.startTransaction();

        const serviceRequest = await ServiceRequest.findById(requestId).session(session);

        if (!serviceRequest) {
            await safeAbort();
            return res.status(404).json({ message: "Service request not found" });
        }

        if (serviceRequest.customerId.toString() !== customerId.toString()) {
            await safeAbort();
            return res.status(403).json({ message: "Not allowed to submit feedback for this request" });
        }

        if (serviceRequest.status !== "completed") {
            await safeAbort();
            return res.status(400).json({ message: "Cannot submit feedback unless request is completed" });
        }

        if (serviceRequest.hasFeedback) {
            await safeAbort();
            return res.status(400).json({ message: "Feedback already submitted for this request" });
        }

        const feedbackDoc = await Feedback.create(
            [
                {
                    requestId: serviceRequest._id,
                    customerId: serviceRequest.customerId,
                    workerId: serviceRequest.workerId,
                    ratingX2,
                    comment,
                },
            ],
            { session }
        );

        const feedback = feedbackDoc[0];
        const updatedWorker = await WorkerProfile.findByIdAndUpdate(serviceRequest.workerId, {
            $inc: { ratingSumX2: ratingX2, ratingCount: 1 },
        },
            {
                new: true,
                session
            }
        );
        if (!updatedWorker) {
            await safeAbort();
            return res.status(400).json({ message: "Worker profile not found" });
        }
        updatedWorker.ratingAvg = Math.round(((updatedWorker.ratingSumX2 / updatedWorker.ratingCount) / 2) * 100) / 100;
        await updatedWorker.save({ session });


        serviceRequest.hasFeedback = true;
        serviceRequest.ratedAt = new Date();
        await serviceRequest.save({ session });

        await session.commitTransaction();


        return res.status(201).json({
            message: "Feedback submitted successfully",
            feedback: {
                _id: feedback._id,
                requestId: feedback.requestId,
                workerId: feedback.workerId,
                customerId: feedback.customerId,
                rating: feedback.ratingX2 / 2,
                comment: feedback.comment,
                createdAt: feedback.createdAt,
            },
            workerRating: {
                avg: updatedWorker.ratingAvg,
                count: updatedWorker.ratingCount,
            },
        });
    } catch (err) {

        if (err?.code === 11000) {
            await safeAbort();
            return res.status(400).json({ message: "Feedback already submitted for this request" });
        }

        await safeAbort();

        console.error("submitFeedback error:", err);
        return res.status(500).json({ message: "Internal server error" });
    } finally {
        session.endSession();
    }
};


