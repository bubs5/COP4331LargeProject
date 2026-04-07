import { useEffect, useMemo, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import "../css/quiz.css";
import { getStudySets, getCardsForSet, getStudySetById, deleteStudySet } from "../services/setsService";import type { StudySet, Flashcard } from "../types";
//defines the structure of each quiz question
type QuizQuestion = {
    id: number;
    question: string;
    options: string[];
    correctAnswer: string;
};

//helper function to shuffle answers randomly
function shuffleArray<T>(array: T[]): T[] {
    const copy = [...array];
    for (let i = copy.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
}

function Quiz() {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();

    //all available study sets
    const [studySets, setStudySets] = useState<StudySet[]>([]);

    //selected set id (from URL or user click)
    const [chosenSetId, setChosenSetId] = useState(searchParams.get("setId") || "");

    //currently selected set object
    const [selectedSet, setSelectedSet] = useState<StudySet | null>(null);

    //flashcards for selected set
    const [cards, setCards] = useState<Flashcard[]>([]);

    //loading states
    const [loadingSets, setLoadingSets] = useState(true);
    const [loadingQuiz, setLoadingQuiz] = useState(false);

    //error message
    const [error, setError] = useState("");

    //quiz progress state
    const [currentIndex, setCurrentIndex] = useState(0);
    const [selectedAnswer, setSelectedAnswer] = useState("");
    const [showFeedback, setShowFeedback] = useState(false);
    const [score, setScore] = useState(0);
    const [quizComplete, setQuizComplete] = useState(false);

    //load all study sets when page loads
    useEffect(() => {
        async function loadSets() {
            try {
                setLoadingSets(true);
                setError("");
                const data = await getStudySets();
                setStudySets(data);
            } catch (err) {
                console.error(err);
                setError("Failed to load study sets.");
            } finally {
                setLoadingSets(false);
            }
        }

        loadSets();
    }, []);

    //load selected set + its cards when chosenSetId changes
    useEffect(() => {
        async function loadQuizData() {

            //if no set selected, reset everything
            if (!chosenSetId) {
                setSelectedSet(null);
                setCards([]);
                return;
            }

            try {
                setLoadingQuiz(true);
                setError("");

                //fetch set info and its cards at same time
                const [fetchedSet, fetchedCards] = await Promise.all([
                    getStudySetById(chosenSetId),
                    getCardsForSet(chosenSetId),
                ]);

                //handle invalid set
                if (!fetchedSet) {
                    setError("That study set could not be found.");
                    setLoadingQuiz(false);
                    return;
                }

                //handle empty set
                if (fetchedCards.length === 0) {
                    setSelectedSet(fetchedSet);
                    setCards([]);
                    setError("This set has no flashcards yet. Add cards before taking the quiz.");
                    setLoadingQuiz(false);
                    return;
                }

                //store data
                setSelectedSet(fetchedSet);
                setCards(fetchedCards);

                //reset quiz state
                setCurrentIndex(0);
                setSelectedAnswer("");
                setShowFeedback(false);
                setScore(0);
                setQuizComplete(false);

                //save last opened set
                localStorage.setItem("lastSet", JSON.stringify(fetchedSet));

            } catch (err) {
                console.error(err);
                setError("Failed to load quiz data.");
            } finally {
                setLoadingQuiz(false);
            }
        }

        loadQuizData();
    }, [chosenSetId]);

    //convert flashcards into quiz questions
    const quizQuestions: QuizQuestion[] = useMemo(() => {
        return cards.map((card) => {

            //get wrong answers from other cards
            const wrongAnswers = cards
                .filter((item) => item.id !== card.id)
                .map((item) => item.definition);

            //pick 3 random wrong answers
            const randomWrong = shuffleArray(wrongAnswers).slice(0, 3);

            return {
                id: card.id,
                question: card.term,
                correctAnswer: card.definition,
                options: shuffleArray([card.definition, ...randomWrong]),
            };
        });
    }, [cards]);

    //when user clicks an answer
    const handleAnswerClick = (answer: string) => {
        if (showFeedback) return;

        setSelectedAnswer(answer);
        setShowFeedback(true);

        //increase score if correct
        if (answer === quizQuestions[currentIndex].correctAnswer) {
            setScore((prev) => prev + 1);
        }
    };

    //move to next question
    const handleNext = () => {
        if (currentIndex === quizQuestions.length - 1) {
            setQuizComplete(true);
            return;
        }

        setCurrentIndex((prev) => prev + 1);
        setSelectedAnswer("");
        setShowFeedback(false);
    };

    //restart entire quiz
    const restartQuiz = () => {
        setCurrentIndex(0);
        setSelectedAnswer("");
        setShowFeedback(false);
        setScore(0);
        setQuizComplete(false);
    };

    //delete a study set from the quiz picker
    const handleDeleteSet = async (setId: string) => {
        const confirmed = window.confirm("Delete this study set?");
        if (!confirmed) return;

        try {
            await deleteStudySet(setId);

            const updatedSets = await getStudySets();
            setStudySets(updatedSets);

            if (chosenSetId === setId) {
                setChosenSetId("");
                setSelectedSet(null);
                setCards([]);
            }
        } catch (err) {
            console.error(err);
            setError("Failed to delete study set.");
        }
    };

    if (!chosenSetId) {
        return (
            <div className="quiz-container">

                <div className="flashcards-actions">
                    <span
                        className="view-all"
                        onClick={() => navigate("/sets")}
                    >
                        New Set
                    </span>
                </div>

                <div className="flashcards-heading">
                    <h1>Choose a set to quiz</h1>
                    <p>Select a study set to begin.</p>
                </div>

                {loadingSets ? (
                    <div className="quiz-state">
                        <h2>Loading study sets...</h2>
                    </div>
                ) : error ? (
                    <div className="quiz-state">
                        <h2>{error}</h2>
                        <button className="primary-btn" onClick={() => navigate("/dashboard")}>
                            Back to Dashboard
                        </button>
                    </div>
                ) : studySets.length === 0 ? (
                    <div className="quiz-state">
                        <h2>No study sets available.</h2>
                        <button className="primary-btn" onClick={() => navigate("/sets")}>
                            Create New Set
                        </button>
                    </div>
                ) : (

                  <div className="set-picker-list">
    {studySets.map((set) => (
        <div
            key={set.id}
            className="set-picker-card"
            onClick={() => setChosenSetId(set.id)}
            style={{ cursor: "pointer" }}
        >
            <div className="set-picker-copy">
                <h3>{set.title}</h3>
                <p>{set.description}</p>

                <span className="set-picker-count">
                    {set.cardCount} cards
                </span>
            </div>

            <div className="set-card-actions">
                <button
                    className="secondary-btn"
                    onClick={(e) => {
                        e.stopPropagation(); //prevents opening quiz
                        navigate(`/sets/${set.id}`);
                    }}
                >
                    Edit
                </button>

                <button
                    className="danger-btn"
                    onClick={(e) => {
                        e.stopPropagation(); //prevents opening quiz
                        handleDeleteSet(set.id);
                    }}
                >
                    Delete
                </button>
            </div>
        </div>
    ))}
</div>
                )}
            </div>
        );
    }

    //loading quiz
    if (loadingQuiz) {
        return (
            <div className="quiz-state">
                <h2>Loading quiz...</h2>
            </div>
        );
    }

    //error screen
    if (error) {
        return (
            <div className="quiz-state">
                <h2>{error}</h2>
                <button
                    className="primary-btn"
                    onClick={() => setChosenSetId("")}
                >
                    Choose Another Set
                </button>
            </div>
        );
    }

    //no questions fallback
    if (quizQuestions.length === 0) {
        return (
            <div className="quiz-state">
                <h2>No quiz questions available.</h2>
                <button
                    className="primary-btn"
                    onClick={() => setChosenSetId("")}
                >
                    Choose Another Set
                </button>
            </div>
        );
    }

    //results screen
    if (quizComplete) {
        return (
            <div className="quiz-container results-screen">
                <p className="eyebrow">Quiz Complete</p>
                <h1>{selectedSet?.title || "Your Results"}</h1>
                <p className="results-copy">
                    You got {score} out of {quizQuestions.length} correct.
                </p>

                <div className="results-actions">
                    <button className="primary-btn" onClick={restartQuiz}>
                        Restart Quiz
                    </button>
                    <button
                        className="secondary-btn"
                        onClick={() => setChosenSetId("")}
                    >
                        Change Set
                    </button>
                </div>
            </div>
        );
    }

    //current question + progress
    const currentQuestion = quizQuestions[currentIndex];
    const progressPercent = Math.round(((currentIndex + 1) / quizQuestions.length) * 100);

    return (
        <div className="quiz-container">

            <div className="quiz-topbar">
                <button
                    className="secondary-btn"
                    onClick={() => setChosenSetId("")}
                >
                    Change Set
                </button>

                <div className="quiz-title-block">
                    <p className="eyebrow">Quiz Mode</p>
                    <h1>{selectedSet?.title || "Test Yourself"}</h1>
                    <p>Choose the correct definition for each term.</p>
                </div>

                <button
                    className="secondary-btn"
                    onClick={() => navigate("/dashboard")}
                >
                    Home
                </button>
            </div>

            <div className="progress-row">
                <div className="progress-meta">
                    <span>Question {currentIndex + 1} of {quizQuestions.length}</span>
                    <span>Score: {score}</span>
                </div>
                <div className="progress-track">
                    <div className="progress-fill" style={{ width: `${progressPercent}%` }} />
                </div>
            </div>

            <div className="quiz-card">
                <span className="card-face-label">Term</span>
                <h2>{currentQuestion.question}</h2>

                <div className="quiz-options">
                    {currentQuestion.options.map((option, index) => {
                        let buttonClass = "quiz-option";

                        if (showFeedback) {
                            if (option === currentQuestion.correctAnswer) {
                                buttonClass += " correct";
                            } else if (option === selectedAnswer) {
                                buttonClass += " incorrect";
                            }
                        }

                        return (
                            <button
                                key={index}
                                className={buttonClass}
                                onClick={() => handleAnswerClick(option)}
                                disabled={showFeedback}
                            >
                                {option}
                            </button>
                        );
                    })}
                </div>

                {showFeedback && (
                    <p className="quiz-feedback">
                        {selectedAnswer === currentQuestion.correctAnswer
                            ? "Correct!"
                            : `Correct answer: ${currentQuestion.correctAnswer}`}
                    </p>
                )}
            </div>

            <div className="button-group">
                <button
                    className="primary-btn"
                    onClick={handleNext}
                    disabled={!showFeedback}
                >
                    {currentIndex === quizQuestions.length - 1 ? "Finish Quiz" : "Next Question"}
                </button>
            </div>
        </div>
    );
}

export default Quiz;
