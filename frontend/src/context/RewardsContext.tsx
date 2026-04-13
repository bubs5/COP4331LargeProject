import{
    createContext,
    useContext,
    useEffect,
    useState,
    useCallback,
    type ReactNode,
} from "react";
import {
    loadRewards,
    awardPoints,
    unlockTheme,
    setActiveTheme,
    applyTheme,
    REWARD_EVENTS,
} from "../services/rewardsService";
import type { RewardsState, RewardEventType, PointHistoryEntry } from "../types/rewards";

interface PointToast{
    id: string;
    points: number;
    label: string;
    icon: string;
}

interface RewardsContextValue{
    rewards: RewardsState;
    toast: PointToast | null;
    award: (type: RewardEventType, multiplier?: number) => PointHistoryEntry;
    unlock: (themeId: string) => void;
    activate: (themeId: string) => void;
    dismissToast: () => void;
}

const RewardsContext = createContext<RewardsContextValue | null>(null);

export function RewardsProvider({ children }: { children: ReactNode }) {
    const [rewards, setRewards] = useState<RewardsState>(loadRewards);
    const [toast, setToast] = useState<PointToast | null>(null);

    //apply theme on mount and whenever activeThemeId changes
    useEffect(() =>{
        applyTheme(rewards.activeThemeId);
    }, [rewards.activeThemeId]);

    const award = useCallback(
        (type: RewardEventType, multiplier = 1): PointHistoryEntry => {
            const { state, entry } = awardPoints(rewards, type, multiplier);
            setRewards(state);

            //show floating toast

            const event = REWARD_EVENTS[type];
            setToast({ id: entry.id, points: entry.points, label: entry.label, icon: event.icon });
            setTimeout(() => setToast(null), 2800);

            return entry;
        },
        [rewards]
    );

    const unlock = useCallback(
        (themeId: string) => {
            const updated = unlockTheme(rewards, themeId);
            setRewards(updated);
        },
        [rewards]
    );

    const activate = useCallback(
        (themeId: string) => {
            const updated = setActiveTheme(rewards, themeId);
            setRewards(updated);
            applyTheme(themeId);
        },
        [rewards]
    );

    const dismissToast = useCallback(() => setToast(null), []);

    return (
        <RewardsContext.Provider value={{ rewards, toast, award, unlock, activate, dismissToast }}>
            {children}
        </RewardsContext.Provider>
    );
}

export function useRewards(): RewardsContextValue{
    const ctx = useContext(RewardsContext);
    if (!ctx) throw new Error("useRewards must be used within <RewardsProvider>");
    return ctx;
}
