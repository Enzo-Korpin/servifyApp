import express from "express";

import { protectRoute } from "../middleware/protecteRoute.js";

import {
  getCustomerProfile,
  updateCustomerProfile,
  getFilteredWorkers,
  searchWorkersByName,
  searchFilteredWorkers,
  getLocation,
} from "../service/customerService.js";
import { filterValidation } from "../middleware/filterValidation.js";
import { CustomerProfileValidation } from "../middleware/CustomerProfileValidation.js";
import { searchTextValidation } from "../middleware/searchTextValidation.js";
import { searchFilteredWorkersValidation } from "../middleware/searchFilteredWorkersValidation.js";

const router = express.Router();

router.get("/profile", protectRoute, getCustomerProfile);
router.put("/profile", protectRoute, CustomerProfileValidation, updateCustomerProfile);

router.get(
  "/filtered-workers",
  protectRoute,
  filterValidation,
  getFilteredWorkers,
);

router.get(
  "/search-workers",
  protectRoute,
  searchTextValidation,
  searchWorkersByName,
);

router.get(
  "/search-filtered-workers",
  protectRoute,
  searchFilteredWorkersValidation,
  searchFilteredWorkers,
);

router.get("/get-location", protectRoute, getLocation);

export default router;
