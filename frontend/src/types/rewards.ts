// Rewards Types

export interface RewardEvent{
    type: RewardEventType;
    points: number;
    label: string;
    icon: string;
}

export type RewardEventType =
    | "quiz_complete"
    | "quiz_perfect"
    | "flashcard_session"
    | "study_streak"
    | "set_created"
    | "daily_login"
    | "cards_studied";

export interface Theme{
    id: string;
    name: string;
    cost: number;
    unlocked: boolean;
    colors: {
        bg: string;
        surface: string;
        card: string;
        primary: string;
        accent: string;
        text: string;
        textSub: string;
        border: string;
        gradient: string;
    };
    preview: string; //css gradient string for preview swatch
    badge?: string;
}

export interface RewardsState{
    totalPoints: number;
    lifetimePoints: number;
    activeThemeId: string;
    unlockedThemeIds: string[];
    history: PointHistoryEntry[];
    streak: number;
    lastActivityDate: string;
}

export interface PointHistoryEntry{
    id: string;
    type: RewardEventType;
    points: number;
    label: string;
    date: string; // ISO string
}
