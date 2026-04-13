const express = require('express');
const{ createDefaultReward } = require('../models/Reward');

module.exports = function createRewardsRouter(rewardsCollection){
    const router = express.Router();

    const REWARD_EVENTS ={
        daily_login:{ points: 10, label: "Daily Login" },
        flashcard_session:{ points: 20, label: "Flashcard Session" },
        cards_studied:{ points: 5, label: "Cards Studied" },
        quiz_complete:{ points: 30, label: "Quiz Completed" },
        quiz_perfect:{ points: 75, label: "Perfect Quiz Score!" },
        set_created:{ points: 15, label: "New Set Created" },
        study_streak:{ points: 50, label: "Study Streak Bonus" }
    };

    const THEMES ={
        default:{ cost: 0 },
        aurora:{ cost: 150 },
        crimson:{ cost: 200 },
        solar:{ cost: 250 },
        frost:{ cost: 300 },
        obsidian:{ cost: 400 }
    };

    router.get('/:userId', async (req, res) =>{
        try{
            const{ userId } = req.params;

            let rewards = await rewardsCollection.findOne({ userId });

            if (!rewards){
                rewards = createDefaultReward(userId);
                await rewardsCollection.insertOne(rewards);
            }

            res.status(200).json(rewards);
        } catch (err){
            console.error('GET /api/rewards/:userId error:', err);
            res.status(500).json({ error: 'Failed to fetch rewards' });
        }
    });

    router.post('/award', async (req, res) =>{
        try{
            const{ userId, eventType, multiplier = 1 } = req.body;

            if (!userId || !eventType){
                return res.status(400).json({ error: 'userId and eventType are required' });
            }

            if (!REWARD_EVENTS[eventType]){
                return res.status(400).json({ error: 'Invalid reward event type' });
            }

            let rewards = await rewardsCollection.findOne({ userId });

            if (!rewards){
                rewards = createDefaultReward(userId);
                await rewardsCollection.insertOne(rewards);
            }

            const event = REWARD_EVENTS[eventType];
            const earned = Math.round(event.points * Number(multiplier));

            const today = new Date().toISOString().split('T')[0];
            const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

            let newStreak = rewards.streak || 0;

            if (rewards.lastActivityDate === yesterday){
                newStreak += 1;
            } else if (rewards.lastActivityDate !== today){
                newStreak = 1;
            }

            const entry ={
                type: eventType,
                points: earned,
                label: event.label,
                date: new Date()
            };

            await rewardsCollection.updateOne(
               { userId },
               {
                    $inc:{
                        totalPoints: earned,
                        lifetimePoints: earned
                    },
                    $push:{
                        history:{
                            $each: [entry],
                            $position: 0,
                            $slice: 50
                        }
                    },
                    $set:{
                        streak: newStreak,
                        lastActivityDate: today
                    }
                }
            );

            const updatedRewards = await rewardsCollection.findOne({ userId });

            res.status(200).json({
                message: 'Points awarded successfully',
                rewards: updatedRewards,
                entry
            });
        } catch (err){
            console.error('POST /api/rewards/award error:', err);
            res.status(500).json({ error: 'Failed to award points' });
        }
    });

    router.post('/unlock', async (req, res) =>{
        try{
            const{ userId, themeId } = req.body;

            if (!userId || !themeId){
                return res.status(400).json({ error: 'userId and themeId are required' });
            }

            if (!THEMES[themeId]){
                return res.status(400).json({ error: 'Theme not found' });
            }

            let rewards = await rewardsCollection.findOne({ userId });

            if (!rewards){
                rewards = createDefaultReward(userId);
                await rewardsCollection.insertOne(rewards);
            }

            if (rewards.unlockedThemeIds.includes(themeId)){
                return res.status(400).json({ error: 'Theme already unlocked' });
            }

            const cost = THEMES[themeId].cost;

            if (rewards.totalPoints < cost){
                return res.status(400).json({ error: 'Not enough points' });
            }

            await rewardsCollection.updateOne(
               { userId },
               {
                    $inc:{ totalPoints: -cost },
                    $push:{ unlockedThemeIds: themeId }
                }
            );

            const updatedRewards = await rewardsCollection.findOne({ userId });

            res.status(200).json({
                message: 'Theme unlocked successfully',
                rewards: updatedRewards
            });
        } catch (err){
            console.error('POST /api/rewards/unlock error:', err);
            res.status(500).json({ error: 'Failed to unlock theme' });
        }
    });

    router.post('/activate', async (req, res) =>{
        try{
            const{ userId, themeId } = req.body;

            if (!userId || !themeId){
                return res.status(400).json({ error: 'userId and themeId are required' });
            }

            let rewards = await rewardsCollection.findOne({ userId });

            if (!rewards){
                rewards = createDefaultReward(userId);
                await rewardsCollection.insertOne(rewards);
            }

            if (!rewards.unlockedThemeIds.includes(themeId)){
                return res.status(400).json({ error: 'Theme not unlocked' });
            }

            await rewardsCollection.updateOne(
               { userId },
               { $set:{ activeThemeId: themeId } }
            );

            const updatedRewards = await rewardsCollection.findOne({ userId });

            res.status(200).json({
                message: 'Theme activated successfully',
                rewards: updatedRewards
            });
        } catch (err){
            console.error('POST /api/rewards/activate error:', err);
            res.status(500).json({ error: 'Failed to activate theme' });
        }
    });

    return router;
};