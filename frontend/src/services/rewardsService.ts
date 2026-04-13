import type {
    RewardsState,
    RewardEventType,
    Theme,
    PointHistoryEntry,
} from "../types/rewards";

//Point values per event
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

// storage key
const STORAGE_KEY = "rewards_state";

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

export function loadRewards(): RewardsState{
    try{
        const raw = localStorage.getItem(STORAGE_KEY);
        if (!raw) return defaultState();
        return { ...defaultState(), ...JSON.parse(raw) };
    }
    catch{
        return defaultState();
    }
}

export function saveRewards(state: RewardsState): void{
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

/** Award points for an event. Returns updated state and entry added. */
export function awardPoints(
    state: RewardsState,
    eventType: RewardEventType,
    multiplier = 1
): { state: RewardsState; entry: PointHistoryEntry } {
    const event = REWARD_EVENTS[eventType];
    const earned = Math.round(event.points * multiplier);

    const today = new Date().toISOString().split("T")[0];

    //streak logic so if last activity was yesterday add to streak
    let newStreak = state.streak;
    const yesterday = new Date(Date.now() - 86_400_000).toISOString().split("T")[0];
    if (state.lastActivityDate === yesterday){
        newStreak += 1;
    }
    else if (state.lastActivityDate !== today){
        newStreak = 1;
    }

    const entry: PointHistoryEntry = {
        id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
        type: eventType,
        points: earned,
        label: event.label,
        date: new Date().toISOString(),
    };

    const updated: RewardsState = {
        ...state,
        totalPoints: state.totalPoints + earned,
        lifetimePoints: state.lifetimePoints + earned,
        history: [entry, ...state.history].slice(0, 50), // keep last 50
        streak: newStreak,
        lastActivityDate: today,
    };

    saveRewards(updated);
    return { state: updated, entry };
}

/** Spend points to unlock a theme. Returns updated state or throws if not enough. */
export function unlockTheme(
    state: RewardsState,
    themeId: string
): RewardsState {
    const theme = THEMES.find((t) => t.id === themeId);
    if (!theme) throw new Error("Theme not found");
    if (state.unlockedThemeIds.includes(themeId)) throw new Error("Already unlocked");
    if (state.totalPoints < theme.cost) throw new Error("Not enough points");

    const updated: RewardsState = {
        ...state,
        totalPoints: state.totalPoints - theme.cost,
        unlockedThemeIds: [...state.unlockedThemeIds, themeId],
    };
    saveRewards(updated);
    return updated;
}

/** Set to active theme. */
export function setActiveTheme(
    state: RewardsState,
    themeId: string
): RewardsState{
    if (!state.unlockedThemeIds.includes(themeId)) throw new Error("Theme not unlocked");
    const updated = { ...state, activeThemeId: themeId };
    saveRewards(updated);
    return updated;
}

/** Apply a theme's CSS variables to :root */
export function applyTheme(themeId: string): void{
    const theme = THEMES.find((t) => t.id === themeId) ?? THEMES[0];
    const root = document.documentElement;
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

/** Get a theme object by id */
export function getThemeById(id: string): Theme{
    return THEMES.find((t) => t.id === id) ?? THEMES[0];
}
