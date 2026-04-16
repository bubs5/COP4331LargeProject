import{
    createContext,
    useContext,
    useEffect,
    useState,
    useCallback,
    type ReactNode,
} from "react";
import{
    loadRewards,
    awardPoints,
    unlockTheme,
    setActiveTheme,
    applyTheme,
    REWARD_EVENTS,
} from "../services/rewardsService";
import type{ RewardsState, RewardEventType, PointHistoryEntry } from "../types/rewards";

interface PointToast{
    id: string;
    points: number;
    label: string;
    icon: string;
}

interface RewardsContextValue{
    rewards: RewardsState;
    loading: boolean;
    toast: PointToast | null;
    award: (type: RewardEventType, multiplier?: number) => Promise<PointHistoryEntry>;
    unlock: (themeId: string) => Promise<void>;
    activate: (themeId: string) => Promise<void>;
    dismissToast: () => void;
}

const RewardsContext = createContext<RewardsContextValue | null>(null);

const DEFAULT_STATE: RewardsState ={
    totalPoints: 0,
    lifetimePoints: 0,
    activeThemeId: "default",
    unlockedThemeIds: ["default"],
    history: [],
    streak: 0,
    lastActivityDate: "",
};

export function RewardsProvider({ children }:{ children: ReactNode }){
    const [rewards, setRewards] = useState<RewardsState>(DEFAULT_STATE);
    const [loading, setLoading] = useState(true);
    const [toast, setToast]     = useState<PointToast | null>(null);

    // load rewards on mount (works for both mock and API)
    useEffect(() =>{
        loadRewards()
            .then((state) =>{
                setRewards(state);
                applyTheme(state.activeThemeId);
            })
            .catch((err) =>{
                console.error("Failed to load rewards:", err);
                applyTheme("default");
            })
            .finally(() => setLoading(false));
    }, []);

    // re-apply theme whenever it changes
    useEffect(() =>{
        applyTheme(rewards.activeThemeId);
    }, [rewards.activeThemeId]);

    const award = useCallback(
        async (type: RewardEventType, multiplier = 1): Promise<PointHistoryEntry> =>{
            const{ state, entry } = await awardPoints(rewards, type, multiplier);
            setRewards(state);
            const event = REWARD_EVENTS[type];
            setToast({ id: entry.id, points: entry.points, label: entry.label, icon: event.icon });
            setTimeout(() => setToast(null), 2800);
            return entry;
        },
        [rewards]
    );

    const unlock = useCallback(
        async (themeId: string) =>{
            const updated = await unlockTheme(rewards, themeId);
            setRewards(updated);
        },
        [rewards]
    );

    const activate = useCallback(
        async (themeId: string) =>{
            const updated = await setActiveTheme(rewards, themeId);
            setRewards(updated);
            applyTheme(themeId);
        },
        [rewards]
    );

    const dismissToast = useCallback(() => setToast(null), []);

    return (
        <RewardsContext.Provider value={{ rewards, loading, toast, award, unlock, activate, dismissToast }}>
           {children}
        </RewardsContext.Provider>
    );
}

export function useRewards(): RewardsContextValue{
    const ctx = useContext(RewardsContext);
    if (!ctx) throw new Error("useRewards must be used within <RewardsProvider>");
    return ctx;
}
