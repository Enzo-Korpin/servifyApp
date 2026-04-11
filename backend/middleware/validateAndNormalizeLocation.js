export const validateAndNormalizeLocation = (location) => {
  if (!location || typeof location !== "object") {
    throw new BadRequestError("Location is required", "LOCATION_REQUIRED");
  }

  const { type, coordinates } = location;

  if (type !== "Point") {
    throw new BadRequestError(
      "Location type must be Point",
      "INVALID_LOCATION_TYPE",
    );
  }

  if (
    !Array.isArray(coordinates) ||
    coordinates.length !== 2 ||
    !coordinates.every(
      (value) => typeof value === "number" && Number.isFinite(value),
    )
  ) {
    throw new BadRequestError(
      "Location coordinates must be [lng, lat]",
      "INVALID_LOCATION_COORDINATES",
    );
  }

  const [lng, lat] = coordinates;

  if (lng < -180 || lng > 180 || lat < -90 || lat > 90) {
    throw new BadRequestError(
      "Invalid longitude or latitude values",
      "INVALID_LOCATION_RANGE",
    );
  }

  return {
    type: "Point",
    coordinates: [lng, lat],
  };
};
