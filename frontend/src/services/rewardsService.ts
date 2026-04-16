import type {
    RewardsState,
    RewardEventType,
    Theme,
    PointHistoryEntry,
} from "../types/rewards";

const urlBase = import.meta.env.VITE_API_URL || "http://localhost:5000/api";

// point values
export const REWARD_EVENTS: Record<RewardEventType, { points: number; label: string; icon: string }> = {
    daily_login:       { points: 10,  label: "Daily Login",          icon: "☀️" },
    flashcard_session: { points: 20,  label: "Flashcard Session",    icon: "🃏" },
    cards_studied:     { points: 5,   label: "Cards Studied",        icon: "📖" },
    quiz_complete:     { points: 30,  label: "Quiz Completed",       icon: "✅" },
    quiz_perfect:      { points: 75,  label: "Perfect Quiz Score!",  icon: "🏆" },
    set_created:       { points: 15,  label: "New Set Created",      icon: "✨" },
    study_streak:      { points: 50,  label: "Study Streak Bonus",   icon: "🔥" },
};

// available themes
export const THEMES: Theme[] = [
    {
        id: "default",
        name: "Midnight",
        cost: 0,
        unlocked: true,
        preview: "linear-gradient(135deg, #080B1C, #4F6FFF)",
        colors: {
            bg: "#080B1C",
            surface: "#0C1022",
            card: "#0F1428",
            primary: "#4F6FFF",
            accent: "#8B6FFF",
            text: "#E8EAF6",
            textSub: "#7B8CAD",
            border: "rgba(99,120,255,0.18)",
            gradient: "linear-gradient(135deg, #4F6FFF, #7C3AED)",
        },
    },
    {
        id: "aurora",
        name: "Aurora",
        cost: 150,
        unlocked: false,
        preview: "linear-gradient(135deg, #0a2a1a, #00c97a)",
        colors: {
            bg: "#060F0A",
            surface: "#0A1810",
            card: "#0D1F14",
            primary: "#00C97A",
            accent: "#00E5A0",
            text: "#E0F5EC",
            textSub: "#7AADA0",
            border: "rgba(0,201,122,0.18)",
            gradient: "linear-gradient(135deg, #00C97A, #0068A4)",
        },
    },
    {
        id: "crimson",
        name: "Crimson",
        cost: 200,
        unlocked: false,
        preview: "linear-gradient(135deg, #1a0508, #FF4466)",
        colors: {
            bg: "#0E0205",
            surface: "#160308",
            card: "#1C040A",
            primary: "#FF4466",
            accent: "#FF6B8A",
            text: "#F5E0E4",
            textSub: "#AD7A85",
            border: "rgba(255,68,102,0.18)",
            gradient: "linear-gradient(135deg, #FF4466, #CC2244)",
        },
    },
    {
        id: "solar",
        name: "Solar",
        cost: 250,
        unlocked: false,
        preview: "linear-gradient(135deg, #1a1200, #FFAA00)",
        colors: {
            bg: "#0E0A00",
            surface: "#160F00",
            card: "#1C1400",
            primary: "#FFAA00",
            accent: "#FFCC44",
            text: "#F5F0E0",
            textSub: "#ADA070",
            border: "rgba(255,170,0,0.18)",
            gradient: "linear-gradient(135deg, #FFAA00, #FF6600)",
        },
    },
    {
        id: "frost",
        name: "Frost",
        cost: 300,
        unlocked: false,
        preview: "linear-gradient(135deg, #020D1A, #00BFFF)",
        colors: {
            bg: "#010810",
            surface: "#030E18",
            card: "#051220",
            primary: "#00BFFF",
            accent: "#44D4FF",
            text: "#DFF4FF",
            textSub: "#6EA8C0",
            border: "rgba(0,191,255,0.18)",
            gradient: "linear-gradient(135deg, #00BFFF, #0050AA)",
        },
    },
    {
        id: "obsidian",
        name: "Obsidian",
        cost: 400,
        unlocked: false,
        preview: "linear-gradient(135deg, #0a0a0a, #888)",
        colors: {
            bg: "#050505",
            surface: "#0A0A0A",
            card: "#111111",
            primary: "#AAAAAA",
            accent: "#DDDDDD",
            text: "#EFEFEF",
            textSub: "#777777",
            border: "rgba(200,200,200,0.12)",
            gradient: "linear-gradient(135deg, #888, #444)",
        },
    },
];

// API helpers
function getUserId(): string | null {
    const raw = localStorage.getItem("user_data");
    if (!raw) return null;
    try {
        return JSON.parse(raw).id as string;
    } catch {
        return null;
    }
}

function defaultState(): RewardsState {
    return {
        totalPoints: 0,
        lifetimePoints: 0,
        activeThemeId: "default",
        unlockedThemeIds: ["default"],
        history: [],
        streak: 0,
        lastActivityDate: "",
    };
}

function normalizeDoc(doc: any): RewardsState {
    return {
        totalPoints:      doc.totalPoints      ?? 0,
        lifetimePoints:   doc.lifetimePoints   ?? 0,
        activeThemeId:    doc.activeThemeId    ?? "default",
        unlockedThemeIds: doc.unlockedThemeIds ?? ["default"],
        history: (doc.history ?? []).map((e: any, i: number): PointHistoryEntry => ({
            id:     e._id?.toString() ?? e.id ?? `${Date.now()}-${i}`,
            type:   e.type,
            points: e.points,
            label:  e.label,
            date:   typeof e.date === 'string' ? e.date : new Date(e.date).toISOString(),
        })),
        streak:           doc.streak           ?? 0,
        lastActivityDate: doc.lastActivityDate ?? "",
    };
}

// ─── API functions ───────────────────────────────────────────

export async function loadRewards(): Promise<RewardsState> {
    const userId = getUserId();
    if (!userId) return defaultState(); // not logged in yet

    const res = await fetch(`${urlBase}/rewards/${userId}`);
    if (!res.ok) throw new Error("Failed to load rewards");

    const data = await res.json();
    return normalizeDoc(data);
}

export async function awardPoints(
    state: RewardsState,
    eventType: RewardEventType,
    multiplier = 1
): Promise<{ state: RewardsState; entry: PointHistoryEntry }> {
    const userId = getUserId();
    if (!userId) {
        // not logged in — fallback to local-only so UI doesn't crash
        const event = REWARD_EVENTS[eventType];
        const earned = Math.round(event.points * multiplier);
        const entry: PointHistoryEntry = {
            id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
            type: eventType,
            points: earned,
            label: event.label,
            date: new Date().toISOString(),
        };
        return {
            state: {
                ...state,
                totalPoints: state.totalPoints + earned,
                lifetimePoints: state.lifetimePoints + earned,
                history: [entry, ...state.history].slice(0, 50),
            },
            entry,
        };
    }

    const res = await fetch(`${urlBase}/rewards/award`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, eventType, multiplier }),
    });

    if (!res.ok) throw new Error("Failed to award points");

    const data = await res.json();
    const rewardsDoc = data.rewards || data;
    const entryRaw = data.entry || {};

    const entry: PointHistoryEntry = {
        id:     entryRaw._id?.toString() ?? entryRaw.id ?? String(Date.now()),
        type:   entryRaw.type ?? eventType,
        points: entryRaw.points ?? 0,
        label:  entryRaw.label ?? REWARD_EVENTS[eventType].label,
        date:   entryRaw.date ? (typeof entryRaw.date === 'string' ? entryRaw.date : new Date(entryRaw.date).toISOString()) : new Date().toISOString(),
    };

    return { state: normalizeDoc(rewardsDoc), entry };
}

export async function unlockTheme(
    _state: RewardsState,
    themeId: string
): Promise<RewardsState> {
    const userId = getUserId();
    if (!userId) throw new Error("Not logged in");

    const res = await fetch(`${urlBase}/rewards/unlock`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, themeId }),
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.error ?? "Could not unlock theme");
    return normalizeDoc(data.rewards || data);
}

export async function setActiveTheme(
    _state: RewardsState,
    themeId: string
): Promise<RewardsState> {
    const userId = getUserId();
    if (!userId) throw new Error("Not logged in");

    const res = await fetch(`${urlBase}/rewards/activate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, themeId }),
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.error ?? "Could not activate theme");
    return normalizeDoc(data.rewards || data);
}

// user-side helpers

export function applyTheme(themeId: string): void {
    const theme = THEMES.find((t) => t.id === themeId) ?? THEMES[0];
    const root  = document.documentElement;
    root.style.setProperty("--color-bg",       theme.colors.bg);
    root.style.setProperty("--color-surface",  theme.colors.surface);
    root.style.setProperty("--color-card",     theme.colors.card);
    root.style.setProperty("--color-primary",  theme.colors.primary);
    root.style.setProperty("--color-accent",   theme.colors.accent);
    root.style.setProperty("--color-text",     theme.colors.text);
    root.style.setProperty("--color-text-sub", theme.colors.textSub);
    root.style.setProperty("--color-border",   theme.colors.border);
    root.style.setProperty("--color-gradient", theme.colors.gradient);
}

export function getThemeById(id: string): Theme {
    return THEMES.find((t) => t.id === id) ?? THEMES[0];
}
