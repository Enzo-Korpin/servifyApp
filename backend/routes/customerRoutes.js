import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";

import {
  getCustomerProfile,
  updateCustomerProfile,
  getFilteredWorkers,
  searchWorkersByName,
} from "../controller/customerController.js";
import { filterValidation } from "../middleware/filterValidation.js";
import { searchTextValidation } from "../middleware/searchTextValidation.js";

const router = express.Router();

router.get("/profile", protectRoute, getCustomerProfile);
router.put("/profile", protectRoute, updateCustomerProfile);

router.get(
  "/filtered-workers",
  protectRoute,
  filterValidation,
  getFilteredWorkers
);

router.get(
  "/search-workers",
  protectRoute,
  searchTextValidation,
  searchWorkersByName
);

export default router;
