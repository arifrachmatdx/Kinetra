import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import admin from "firebase-admin";

/**
 * Seed Firestore collection `latihan` from `tool/latihan_seed.json`.
 *
 * Requirements:
 * - Service account key JSON downloaded from Firebase project `kinetra-513fe`
 * - Env var GOOGLE_APPLICATION_CREDENTIALS points to that JSON
 *
 * Run:
 *   npm i firebase-admin
 *   node tool/seed_latihan_admin.mjs
 */

function mustGetEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env var ${name}`);
  return v;
}

function loadSeed() {
  const file = path.resolve("tool", "latihan_seed.json");
  const raw = fs.readFileSync(file, "utf-8");
  const data = JSON.parse(raw);
  if (!Array.isArray(data)) throw new Error("Seed JSON must be an array");
  return data;
}

async function main() {
  mustGetEnv("GOOGLE_APPLICATION_CREDENTIALS");

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();
  const seeds = loadSeed();

  let batch = db.batch();
  let op = 0;

  for (const item of seeds) {
    const latihanId = item.latihanId;
    if (!latihanId) throw new Error("Missing latihanId in seed item");

    const ref = db.collection("latihan").doc(String(latihanId));
    batch.set(ref, item, { merge: true });
    op++;

    // Firestore batch limit: 500 operations
    if (op % 450 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }

  await batch.commit();
  console.log(`Seeded ${seeds.length} docs into collection "latihan".`);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});

