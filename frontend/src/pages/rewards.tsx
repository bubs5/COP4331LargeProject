import { useState } from "react";
import { useRewards } from "../context/RewardsContext";
import { THEMES, REWARD_EVENTS } from "../services/rewardsService";
import "../css/rewards.css";

type Tab = "store" | "history" | "earn";

export default function Rewards(){
    const { rewards, unlock, activate } = useRewards();
    const [tab, setTab] = useState<Tab>("store");
    const [storeError, setStoreError] = useState("");
    const [storeSuccess, setStoreSuccess] = useState("");

    function handleUnlock(themeId: string){
        setStoreError("");
        setStoreSuccess("");
        try{
            unlock(themeId);
            setStoreSuccess("Theme unlocked! Click Activate to use it.");
        }
        catch (e: any){
            setStoreError(e.message || "Could not unlock theme.");
        }
    }

    function handleActivate(themeId: string) {
        setStoreError("");
        setStoreSuccess("");
        activate(themeId);
        setStoreSuccess("Theme activated!");
    }

    // XP bar every 500 points = 1 level
    const level = Math.floor(rewards.lifetimePoints / 500) + 1;
    const levelProgress = ((rewards.lifetimePoints % 500) / 500) * 100;
    const pointsToNext = 500 - (rewards.lifetimePoints % 500);

    return (
        <div className="rewards-page">
            {/*Hero Header*/}
            <div className="rewards-header">
                <div className="rewards-header-left">
                    <p className="rewards-eyebrow">Your Rewards</p>
                    <h1 className="rewards-title">{rewards.totalPoints.toLocaleString()} pts</h1>
                    <p className="rewards-subtitle">
                        {rewards.lifetimePoints.toLocaleString()} lifetime pts
                        &nbsp;·&nbsp;
                        {rewards.streak}-day streak🔥
                    </p>
                </div>

                <div className="rewards-level-badge">
                    <span className="rewards-level-num">Lv {level}</span>
                    <div className="rewards-xp-bar">
                        <div
                            className="rewards-xp-fill"
                            style={{ width: `${levelProgress}%` }}
                        />
                    </div>
                    <p className="rewards-xp-label">{pointsToNext} pts to Lv {level + 1}</p>
                </div>
            </div>

            {/*Tabs */}
            <div className="rewards-tabs">
                {(["store", "earn", "history"] as Tab[]).map((t) => (
                    <button
                        key={t}
                        className={`rewards-tab ${tab === t ? "active" : ""}`}
                        onClick={() => { setTab(t); setStoreError(""); setStoreSuccess(""); }}
                    >
                        {t === "store" ? "Theme Store" : t === "earn" ? "How to Earn" : "History"}
                    </button>
                ))}
            </div>

            {/* Store tab*/}
            {tab === "store" && (
                <div className="rewards-section">
                    {storeError && <p className="rewards-msg error">{storeError}</p>}
                    {storeSuccess && <p className="rewards-msg success">{storeSuccess}</p>}

                    <div className="theme-grid">
                        {THEMES.map((theme) => {
                            const isUnlocked = rewards.unlockedThemeIds.includes(theme.id);
                            const isActive = rewards.activeThemeId === theme.id;
                            const canAfford = rewards.totalPoints >= theme.cost;

                            return (
                                <div
                                    key={theme.id}
                                    className={`theme-card ${isActive ? "theme-card--active" : ""}`}
                                >
                                    {theme.badge && (
                                        <span className="theme-badge">{theme.badge}</span>
                                    )}

                                    <div
                                        className="theme-swatch"
                                        style={{ background: theme.preview }}
                                    >
                                        <div className="theme-swatch-dots">
                                            <span style={{ background: theme.colors.primary }} />
                                            <span style={{ background: theme.colors.accent }} />
                                            <span style={{ background: theme.colors.text }} />
                                        </div>
                                    </div>

                                    <div className="theme-info">
                                        <h3>{theme.name}</h3>
                                        {theme.cost === 0 ? (
                                            <span className="theme-free">Free</span>
                                        ) : (
                                            <span className={`theme-cost ${!canAfford && !isUnlocked ? "theme-cost--locked" : ""}`}>
                                                {theme.cost} pts
                                            </span>
                                        )}
                                    </div>

                                    <div className="theme-actions">
                                        {isActive ? (
                                            <span className="theme-active-label">✓ Active</span>
                                        ) : isUnlocked ? (
                                            <button
                                                className="theme-btn theme-btn--activate"
                                                onClick={() => handleActivate(theme.id)}
                                            >
                                                Activate
                                            </button>
                                        ) : (
                                            <button
                                                className={`theme-btn theme-btn--unlock ${!canAfford ? "disabled" : ""}`}
                                                onClick={() => canAfford && handleUnlock(theme.id)}
                                                disabled={!canAfford}
                                                title={!canAfford ? `Need ${theme.cost - rewards.totalPoints} more pts` : ""}
                                            >
                                                {canAfford ? `Unlock · ${theme.cost}pts` : `🔒 ${theme.cost}pts`}
                                            </button>
                                        )}
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/*Earn tab*/}
            {tab === "earn" && (
                <div className="rewards-section">
                    <p className="earn-intro">Complete activities to earn points and unlock rewards.</p>
                    <div className="earn-list">
                        {Object.entries(REWARD_EVENTS).map(([key, event]) => (
                            <div key={key} className="earn-row">
                                <span className="earn-icon">{event.icon}</span>
                                <span className="earn-label">{event.label}</span>
                                <span className="earn-pts">+{event.points} pts</span>
                            </div>
                        ))}
                    </div>

                    <div className="earn-tip">
                        <span>💡</span>
                        <p>
                            Keep your daily study streak going for bonus multipliers.
                            A perfect quiz score gives <strong>+75 pts</strong> instead of the usual 30!
                        </p>
                    </div>
                </div>
            )}

            {/* History tab*/}
            {tab === "history" && (
                <div className="rewards-section">
                    {rewards.history.length === 0 ? (
                        <p className="history-empty">No activity yet. Start studying to earn points!</p>
                    ) : (
                        <div className="history-list">
                            {rewards.history.map((entry) => (
                                <div key={entry.id} className="history-row">
                                    <span className="history-icon">
                                        {REWARD_EVENTS[entry.type]?.icon ?? "⭐"}
                                    </span>
                                    <div className="history-copy">
                                        <span className="history-label">{entry.label}</span>
                                        <span className="history-date">
                                            {new Date(entry.date).toLocaleDateString("en-US", {
                                                month: "short",
                                                day: "numeric",
                                                hour: "2-digit",
                                                minute: "2-digit",
                                            })}
                                        </span>
                                    </div>
                                    <span className="history-pts">+{entry.points}</span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}
