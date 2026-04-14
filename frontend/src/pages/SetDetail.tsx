import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import "../css/setDetail.css";
import type { Flashcard, StudySet } from "../types";
import {
    getStudySetById,
    getCardsForSet,
    createCardForSet,
    updateCardInSet,
    deleteCardFromSet,
    deleteStudySet,
} from "../services/setsService";

function SetDetail() {
    // get setID from url
    const { setId } = useParams();
    const navigate = useNavigate();

    const [studySet, setStudySet] = useState<StudySet | null>(null);
    const [cards, setCards] = useState<Flashcard[]>([]);
    const [term, setTerm] = useState("");
    const [definition, setDefinition] = useState("");
    const [editingCardId, setEditingCardId] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

    // data fetching
    async function loadSetData() {
        if (!setId) return;

        try {
            setLoading(true);
            const [setData, cardData] = await Promise.all([
                getStudySetById(setId),
                getCardsForSet(setId),
            ]);

            if (!setData) {
                setError("Study set not found.");
                return;
            }

            setStudySet(setData);
            setCards(cardData);
            localStorage.setItem("lastSet", JSON.stringify(setData));
        } catch (err) {
            console.error(err);
            setError("Failed to load this study set.");
        } finally {
            setLoading(false);
        }
    }

    useEffect(() => {
        loadSetData();
    }, [setId]);

    // add or update a card
    async function handleSubmitCard(e: React.FormEvent) {
        e.preventDefault();
        if (!setId || !term.trim() || !definition.trim()) return;

        try {
            if (editingCardId !== null) {
                await updateCardInSet(editingCardId, { term, definition });
            } else {
                await createCardForSet(setId, { term, definition });
            }

            setTerm("");
            setDefinition("");
            setEditingCardId(null);
            await loadSetData();
        } catch (err) {
            console.error(err);
            setError("Failed to save flashcard.");
        }
    }

    // handles edits
    function handleEdit(card: Flashcard) {
        setTerm(card.term);
        setDefinition(card.definition);
        setEditingCardId(card.id);
    }

    // delete a card
    async function handleDeleteCard(cardId: string) {
        const confirmed = window.confirm("Delete this flashcard?");
        if (!confirmed) return;

        try {
            await deleteCardFromSet(cardId);
            await loadSetData();
        } catch (err) {
            console.error(err);
            setError("Failed to delete card.");
        }
    }

    // deletes the entire set
    async function handleDeleteSet() {
        if (!studySet) return;
        const confirmed = window.confirm("Delete this entire study set?");
        if (!confirmed) return;

        try {
            await deleteStudySet(studySet.id);
            navigate("/sets");
        } catch (err) {
            console.error(err);
            setError("Failed to delete study set.");
        }
    }

    if (loading) {
        return <div className="page-state">Loading set...</div>;
    }

    if (error && !studySet) {
        return (
            <div className="page-state error-state">
                <h2>{error}</h2>
                <button className="primary-btn" onClick={() => navigate("/sets")}>
                    Back to Sets
                </button>
            </div>
        );
    }

    if (!studySet) return null;

    return (
        <div className="set-detail-page">
            <div className="set-detail-header">
                <button className="secondary-btn" onClick={() => navigate("/sets")}>
                    Back to Sets
                </button>

                <div className="set-detail-title">
                    <p className="eyebrow">Selected Set</p>
                    <h1>{studySet.title}</h1>
                    <p>{studySet.description}</p>
                </div>

                <div className="set-detail-actions">
                    <button
                        className="primary-btn"
                        onClick={() => navigate(`/flashcards?setId=${studySet.id}`)}
                    >
                        Study This Set
                    </button>
                    <button className="danger-btn" onClick={handleDeleteSet}>
                        Delete Set
                    </button>
                </div>
            </div>

            {error && <div className="page-state error-state">{error}</div>}

            <section className="card-editor-section">
                <h2>
                    {editingCardId !== null ? "Edit Flashcard" : "Add Flashcard"}
                </h2>

                <form onSubmit={handleSubmitCard} className="card-form">
                    <label>Term</label>
                    <input
                        type="text"
                        value={term}
                        onChange={(e) => setTerm(e.target.value)}
                        placeholder="Enter the front of the card"
                    />

                    <label>Definition</label>
                    <textarea
                        value={definition}
                        onChange={(e) => setDefinition(e.target.value)}
                        placeholder="Enter the back of the card"
                    />

                    <div className="card-form-actions">
                        <button className="primary-btn" type="submit">
                            {editingCardId !== null ? "Update Card" : "Add Card"}
                        </button>

                        {editingCardId !== null && (
                            <button
                                type="button"
                                className="secondary-btn"
                                onClick={() => {
                                    setEditingCardId(null);
                                    setTerm("");
                                    setDefinition("");
                                }}
                            >
                                Cancel Edit
                            </button>
                        )}
                    </div>
                </form>
            </section>

            <section className="cards-list-section">
                <div className="cards-list-header">
                    <h2>Cards in this set</h2>
                    <span className="card-badge">{cards.length}</span>
                </div>

                {cards.length === 0 ? (
                    <div className="empty-card">
                        <p>No flashcards yet. Add first one above.</p>
                    </div>
                ) : (
                    <div className="cards-list">
                        {cards.map((card, i) => (
                            <div key={card.id} className="flashcard-row">
                                <div className="flashcard-number">{i + 1}</div>

                                <div className="flashcard-copy">
                                    <h3>{card.term}</h3>
                                    <p>{card.definition}</p>
                                </div>

                                <div className="flashcard-row-actions">
                                    <button
                                        className="secondary-btn"
                                        onClick={() => handleEdit(card)}
                                    >
                                        Edit
                                    </button>
                                    <button
                                        className="danger-btn"
                                        onClick={() => handleDeleteCard(card.id)}
                                    >
                                        Delete
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </section>
        </div>
    );
}

export default SetDetail;
