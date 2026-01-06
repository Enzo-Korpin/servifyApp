import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";
import {
  followWorker,
  unfollowWorker,
  getAllFollowingWorkers,
  getFollowingWorker,
} from "../controller/followController.js";

const router = express.Router();

router.post("/follow/:workerId", protectRoute, followWorker);
router.delete("/unfollow/:workerId", protectRoute, unfollowWorker);

router.get("/following", protectRoute, getAllFollowingWorkers);
router.get("/following/:workerId", protectRoute, getFollowingWorker);

export default router;
