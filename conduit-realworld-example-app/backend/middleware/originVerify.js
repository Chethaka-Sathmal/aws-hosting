const { timingSafeEqual } = require("crypto");

// Rejects requests that did not come through CloudFront, which adds the
// X-Origin-Verify header as an origin custom header. Disabled when
// ORIGIN_VERIFY_SECRET is not set (e.g. local development).
const originVerify = (req, res, next) => {
  const secret = process.env.ORIGIN_VERIFY_SECRET;
  if (!secret) return next();

  const expected = Buffer.from(secret);
  const received = Buffer.from(req.get("X-Origin-Verify") || "");

  if (
    received.length === expected.length &&
    timingSafeEqual(received, expected)
  ) {
    return next();
  }

  res.status(403).json({ errors: { body: ["Forbidden"] } });
};

module.exports = originVerify;
