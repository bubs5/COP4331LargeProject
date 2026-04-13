function createDefaultReward(userId) {
    return {
        userId,
        totalPoints: 0,
        lifetimePoints: 0,
        activeThemeId: "default",
        unlockedThemeIds: ["default"],
        history: [],
        streak: 0,
        lastActivityDate: ""
    };
}

module.exports = { createDefaultReward };