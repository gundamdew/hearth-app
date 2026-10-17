"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.dailyMorningDigest = exports.onChoreUpdated = exports.onInventoryUpdated = exports.onBudgetTransactionCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
admin.initializeApp();
/**
 * Sends a push notification and writes an entry into the notifications collection
 */
async function sendPushToHousehold(payload) {
    const db = admin.firestore();
    // 1. Write in-app notification to Firestore activity feed
    await db.collection("notifications").add({
        title: payload.title,
        body: payload.body,
        category: payload.category,
        actorName: payload.actorName,
        targetUser: payload.targetUser || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        readBy: [],
    });
    // 2. Fetch users and collect valid recipient FCM tokens
    const usersSnap = await db.collection("users").get();
    const tokens = [];
    const tokenUserMap = new Map(); // token -> userId
    for (const doc of usersSnap.docs) {
        const user = doc.data();
        const userName = (user.name || "").toString();
        // Skip actor (don't notify the user who performed the action)
        if (payload.actorName && userName.toLowerCase() === payload.actorName.toLowerCase()) {
            continue;
        }
        // If targeted at a specific user, skip others
        if (payload.targetUser && userName.toLowerCase() !== payload.targetUser.toLowerCase()) {
            continue;
        }
        // Skip users with notifications disabled
        if (user.notificationsEnabled === false) {
            continue;
        }
        const userTokens = Array.isArray(user.fcmTokens) ? user.fcmTokens : [];
        for (const token of userTokens) {
            if (token && typeof token === "string" && !tokens.includes(token)) {
                tokens.push(token);
                tokenUserMap.set(token, doc.id);
            }
        }
    }
    if (tokens.length === 0) {
        return;
    }
    // 3. Send multicast push via FCM
    try {
        const response = await admin.messaging().sendEachForMulticast({
            tokens,
            notification: {
                title: payload.title,
                body: payload.body,
            },
            data: {
                category: payload.category,
                actorName: payload.actorName,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                notification: {
                    channelId: "hearth_high_importance_channel",
                    priority: "high",
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: payload.title,
                            body: payload.body,
                        },
                        badge: 1,
                        sound: "default",
                    },
                },
            },
        });
        // 4. Clean up invalid/stale tokens
        if (response.failureCount > 0) {
            for (let i = 0; i < response.responses.length; i++) {
                const resp = response.responses[i];
                if (!resp.success) {
                    const errCode = resp.error?.code;
                    if (errCode === "messaging/invalid-registration-token" ||
                        errCode === "messaging/registration-token-not-registered") {
                        const badToken = tokens[i];
                        const userId = tokenUserMap.get(badToken);
                        if (userId) {
                            await db
                                .collection("users")
                                .doc(userId)
                                .update({
                                fcmTokens: admin.firestore.FieldValue.arrayRemove(badToken),
                            });
                        }
                    }
                }
            }
        }
    }
    catch (error) {
        console.error("Error sending multicast message:", error);
    }
}
// ============================================================================
// TRIGGER 1: Budget and Settlement Transactions
// ============================================================================
exports.onBudgetTransactionCreated = (0, firestore_1.onDocumentCreated)("budget_transactions/{docId}", async (event) => {
    const data = event.data?.data();
    if (!data)
        return;
    const assignee = data.assignee || "Someone";
    const amount = Number(data.amount) || 0;
    const roundedAmount = Math.round(amount);
    if (data.splitType === "settlement") {
        await sendPushToHousehold({
            title: "Settlement Recorded",
            body: `${assignee} settled up the balance (${roundedAmount} USD).`,
            category: "budget",
            actorName: assignee,
        });
    }
    else if (data.type === "expense" && data.splitType === "shared") {
        const title = data.title || "Expense";
        const category = data.category || "General";
        await sendPushToHousehold({
            title: "New Shared Expense",
            body: `${assignee} added ${title} (${roundedAmount} USD) in ${category}.`,
            category: "budget",
            actorName: assignee,
        });
    }
});
// ============================================================================
// TRIGGER 2: Inventory Low Stock Monitor
// ============================================================================
exports.onInventoryUpdated = (0, firestore_1.onDocumentUpdated)("inventory/{docId}", async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    const beforeQty = Number(before.quantity) || 0;
    const afterQty = Number(after.quantity) || 0;
    const threshold = Number(after.lowStockThreshold ?? after.min ?? 2);
    const wasLow = before.isRunningLow ?? beforeQty <= threshold;
    const isNowLow = after.isRunningLow ?? afterQty <= threshold;
    if (!wasLow && isNowLow) {
        const name = after.name || "Item";
        const unit = after.unit || "pcs";
        const location = after.location || "pantry";
        await sendPushToHousehold({
            title: `Running Low: ${name}`,
            body: `Only ${afterQty} ${unit} left in ${location}.`,
            category: "inventory",
            actorName: "System",
        });
    }
});
// ============================================================================
// TRIGGER 3: Chore Completed and Rotation
// ============================================================================
exports.onChoreUpdated = (0, firestore_1.onDocumentUpdated)("chores/{docId}", async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    if (!before.isDone && after.isDone) {
        const assignee = after.assignee || "Someone";
        const choreName = after.name || "Chore";
        await sendPushToHousehold({
            title: "Chore Completed",
            body: `${assignee} finished: ${choreName}.`,
            category: "cleaning",
            actorName: assignee,
        });
    }
});
// ============================================================================
// TRIGGER 4: Daily Morning Briefing at 09:00 Europe/Warsaw
// ============================================================================
exports.dailyMorningDigest = (0, scheduler_1.onSchedule)({
    schedule: "0 9 * * *",
    timeZone: "Europe/Warsaw",
}, async () => {
    const db = admin.firestore();
    // 1. Get today's date in Europe/Warsaw (YYYY-MM-DD)
    const now = new Date();
    const warsawFormatter = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Europe/Warsaw",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
    });
    const todayId = warsawFormatter.format(now); // "YYYY-MM-DD"
    // 2. Query today's meal plan
    let recipeName = "No dinner planned yet";
    try {
        const planDoc = await db.collection("meal_plans").doc(todayId).get();
        if (planDoc.exists) {
            const recipeId = planDoc.data()?.recipeId;
            if (recipeId) {
                const recipeDoc = await db.collection("recipes").doc(recipeId).get();
                if (recipeDoc.exists) {
                    recipeName = recipeDoc.data()?.name || "Planned meal";
                }
            }
        }
    }
    catch (e) {
        console.warn("Could not fetch today's dinner recipe:", e);
    }
    // 3. Query pending chores count
    let pendingCount = 0;
    try {
        const choresSnap = await db
            .collection("chores")
            .where("isDone", "==", false)
            .get();
        pendingCount = choresSnap.size;
    }
    catch (e) {
        console.warn("Could not fetch pending chores:", e);
    }
    await sendPushToHousehold({
        title: "Good morning from Hearth.",
        body: `Tonight's dinner: ${recipeName}. You have ${pendingCount} chores today.`,
        category: "meals",
        actorName: "System",
    });
});
//# sourceMappingURL=index.js.map