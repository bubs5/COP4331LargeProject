import { useEffect, useState, useMemo } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import '../css/flashcards.css';
import { getCardsForSet, getStudySetById, getStudySets } from '../services/setsService'; //gets API data for flashcards
import type { Flashcard, StudySet } from '../types';





function Flashcards() {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const [studySets, setStudySets] = useState<StudySet[]>([]);
    const [chosenSetId, setChosenSetId] = useState(searchParams.get('setId') || '');
    const [cards, setCards] = useState<Flashcard[]>([]);
    const [selectedSet, setSelectedSet] = useState<StudySet | null>(null); //the set we are currently studying
    const [index, setIndex] = useState(0); //what card we are on
    const [showDef, setShowDef] = useState(false); //whether to show term or the definition
    const [sessionComplete, setSessionComplete] = useState(false); //if all the cards have been gone through
    const [knownCards, setKnownCards] = useState<Set<number>>(new Set()); //if the user knows a card
    const [apiLoading, setApiLoading] = useState(true); //true the data is being fetched from the API or not
    const [error, setError] = useState(""); //error messsage is something goes wrong

    const setId = chosenSetId;

    //load all sets
    useEffect(() => {
        async function loadStudySets() {
            try {
                const fetchedSets = await getStudySets();
                setStudySets(fetchedSets);
            } catch (err) {
                console.error(err);
                setError('Failed to load study sets.');
            }
        }

        loadStudySets();
    }, []);

    //load cards for when a set ischosen
    useEffect(() => {
        async function loadFlashcards() {
           //if no set is chosen yet. show picker instead of loading
            if (!setId) {
                setApiLoading(false);
                return;
            }

            try{
                setApiLoading(true);
                setError('');

                const [fetchedSet, fetchedCards] = await Promise.all([
                    getStudySetById(setId),
                    getCardsForSet(setId),
                ]);
                //guard in case set doesnt exist
                if (!fetchedSet){
                    setError('That study set could not be found.');
                    setApiLoading(false);
                    return;
                }
                //guard incase set exist but no cards yet
                if (fetchedCards.length === 0){
                    setSelectedSet(fetchedSet);
                    setCards([]);
                    setError('This set has no flashcards yet. Add cards before studying.');
                    setApiLoading(false);
                    return;
                }

                setSelectedSet(fetchedSet);
                setCards(fetchedCards);
                setIndex(0);
                setShowDef(false);
                setSessionComplete(false);
                setKnownCards(new Set());
                localStorage.setItem('lastSet', JSON.stringify(fetchedSet));
            } catch (err){
                console.error(err);
                setError('Failed to load flashcards. Please try again.');
            } finally{
                setApiLoading(false);
            }
        }

        loadFlashcards();
    }, [setId]);


    //how far into each set we aare
    const progressPercent = useMemo(() =>{
        if (cards.length === 0) return 0;
        return Math.round(((index + 1) / cards.length) * 100);
    }, [cards.length, index]);

    //flip card
    const toggleCard = () =>{
        setShowDef((prev) => !prev);
    };

    //next card
    const nextCard = () =>{
        if (index === cards.length - 1){
            setSessionComplete(true);
            return;
        }

        setShowDef(false);
        setIndex((prev) => prev + 1);
    };  
    // previous card
    const prevCard = () =>{
        setShowDef(false);
        setIndex((prev) => Math.max(prev - 1, 0));
    };

    //mark card as known
    const markKnown = () =>{
        if (cards.length === 0) return;
        setKnownCards((prev) => new Set(prev).add(cards[index].id));
        nextCard();
    };

    //mark card as unknown
    const markUnknown = () =>{
        if (cards.length === 0) return;

        setKnownCards((prev) => {
            const next = new Set(prev);
            next.delete(cards[index].id);
            return next;
        });

        nextCard();
    };

    //restart study session
    const restartSession = () =>{
        setIndex(0);
        setShowDef(false);
        setKnownCards(new Set());
        setSessionComplete(false);
    };

    //keyboard shortcuts
    useEffect(() =>{
        const handleKeyDown = (e: KeyboardEvent) =>{
            if (cards.length === 0 || sessionComplete) return;

            if (e.key === 'ArrowRight') {
                nextCard();
            } else if (e.key === 'ArrowLeft'){
                prevCard();
            } else if (e.key === ' ' || e.key === 'Enter'){
                e.preventDefault();
                toggleCard();
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => {
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, [index, cards, showDef, sessionComplete]);

    //set picker
    if (!setId){
        return(
            <div className="flashcards-state">
                <p className="eyebrow">Flashcards</p>
                <h1>Choose a set to study</h1>
                <p>Select one of your study sets to begin.</p>

                <div className="set-picker-list">
                    {studySets.length === 0 ? (
                        //no sets created yet
                        <div className="empty-picker">
                            <p>You do not have any study sets yet.</p>
                            <button
                                className="primary-btn"
                                onClick={() => navigate('/sets')}
                            >
                                Go to Study Sets
                            </button>
                        </div>
                    ) : (
                        studySets.map((set) => (
                            <button
                                key={set.id}
                                className="set-picker-card"
                                onClick={() => setChosenSetId(set.id)}
                            >
                                <div className="set-picker-copy">
                                    <h3>{set.title}</h3>
                                    <p>{set.description}</p>
                                </div>
                                <span className="set-picker-count">
                                {set.cardCount} cards
                            </span>
                            </button>
                        ))
                    )}
                </div>
            </div>
        );
    }
    //loading
    if (apiLoading){
        return <div className="flashcards-state">Loading flashcards...</div>;
    }

    //error
    if (error){
        return(
            <div className="flashcards-state">
                <h2>{error}</h2>
                <button className="primary-btn" onClick={() => navigate(setId ? `/sets?setId=${setId}` : '/sets')}>
                    Go to Study Sets
                </button>
            </div>
        );
    }

    //session complete screen
    if (sessionComplete){
        return(
            <div className="flashcardContainer complete-screen">
                <p className="eyebrow">Session Complete</p>
                <h1>{selectedSet?.title}</h1>
                <p className="results-copy">
                    You know {knownCards.size} out of {cards.length} cards.
                </p>

                <div className="results-actions">
                    <button className="primary-btn" onClick={restartSession}>Restart Set</button>
                    <button className="secondary-btn" onClick={() => navigate(`/sets/${selectedSet?.id || ''}`)}>
                        Back to Set Builder
                    </button>
                </div>
            </div>
        );
    }
    //empty or missing card
    if (!cards.length || !cards[index]){
        return (
            <div className="flashcards-state">
                <h2>No flashcards available.</h2>
                <button
                    className="primary-btn"
                    onClick={() => navigate('/sets')}
                >
                    Go to Study Sets
                </button>
            </div>
        );
    }
    //ehat card is currently on the screen
    const currentCard = cards[index];

    return(

        <div className="flashcardContainer">
            <div className="flashcards-topbar">
                <button className="secondary-btn" onClick={() => navigate(`/sets?setId=${selectedSet?.id || ''}`)}>
                    Back to Sets
                </button>
                <div className="flashcards-title-block">
                    <p className="eyebrow">Flashcards</p>
                    <h1>{selectedSet?.title || 'Study Mode'}</h1>
                    <p>{selectedSet?.description}</p>
                </div>
                {/*clears all session data and returns to the picker */}
                <button
                    className="secondary-btn"
                    onClick={() => {
                        setChosenSetId('');
                        setSelectedSet(null);
                        setCards([]);
                        setIndex(0);
                        setShowDef(false);
                        setSessionComplete(false);
                        setKnownCards(new Set());
                        setError('');
                    }}
                >
                    Change Set
                </button>
            </div>
            {/*progress bar*/}
            <div className="progress-row">
                <div className="progress-meta">
                    <span>Card {index + 1} of {cards.length}</span>
                    <span>{progressPercent}% through set</span>
                </div>
                <div className="progress-track">
                    <div className="progress-fill" style={{ width: `${progressPercent}%` }} />
                </div>
            </div>

            <div className="flashcard" onClick={toggleCard}>
                {/*lets user know if they are looking at the term or definition*/}
                <span className="card-face-label">{showDef ? 'Definition' : 'Term'}</span>
                <h2>{showDef ? currentCard.definition : currentCard.term}</h2>
                <p>Click the card or press space to flip.</p>
            </div>

            <div className="button-group">
                <button className="secondary-btn" onClick={prevCard} disabled={index === 0}>Previous</button>
                <button className="primary-btn" onClick={toggleCard}>Flip</button>
                <button className="secondary-btn" onClick={nextCard}>Next</button>
            </div>

            <div className="knowldge-buttons">
                <button className="success-btn" onClick={markKnown}>I know this</button>
                <button className="warning-btn" onClick={markUnknown}>Still learning</button>
            </div>
        </div>
    );
}

export default Flashcards;