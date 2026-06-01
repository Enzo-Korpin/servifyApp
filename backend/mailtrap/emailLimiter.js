// import dotenv from "dotenv";
// dotenv.config();

const DAILY_LIMIT = Number(process.env.EMAIL_DAILY_LIMIT || 50);
const PER_RECIPIENT_DAILY_LIMIT = Number(
  process.env.EMAIL_PER_RECIPIENT_DAILY_LIMIT || 3,
);
const COOLDOWN_SECONDS = Number(
  process.env.EMAIL_RESEND_COOLDOWN_SECONDS || 60,
);

// In-memory limits (OK for now). For production use Redis.
const state = {
  dayKey: "",
  totalSentToday: 0,
  perRecipient: new Map(), // email -> { count, lastSentAt }
};

function getDayKey() {
  const d = new Date();
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

function resetIfNewDay() {
  const key = getDayKey();
  if (state.dayKey !== key) {
    state.dayKey = key;
    state.totalSentToday = 0;
    state.perRecipient.clear();
  }
}

/**
 * Returns { ok: true } or { ok:false, reason }
 */
export function checkCanSend(toEmail) {
  resetIfNewDay();

  if (state.totalSentToday >= DAILY_LIMIT) {
    return { ok: false, reason: "Daily email limit reached" };
  }

  const entry = state.perRecipient.get(toEmail) || { count: 0, lastSentAt: 0 };
  const now = Date.now();

  // cooldown
  if (entry.lastSentAt && now - entry.lastSentAt < COOLDOWN_SECONDS * 1000) {
    const wait = Math.ceil(
      (COOLDOWN_SECONDS * 1000 - (now - entry.lastSentAt)) / 1000,
    );
    return { ok: false, reason: `Cooldown active. Try again in ${wait}s` };
  }

  if (entry.count >= PER_RECIPIENT_DAILY_LIMIT) {
    return { ok: false, reason: "Recipient daily limit reached" };
  }

  return { ok: true };
}

export function markSent(toEmail) {
  resetIfNewDay();

  state.totalSentToday += 1;

  const entry = state.perRecipient.get(toEmail) || { count: 0, lastSentAt: 0 };
  entry.count += 1;
  entry.lastSentAt = Date.now();
  state.perRecipient.set(toEmail, entry);
}
