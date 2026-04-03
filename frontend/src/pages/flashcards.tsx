import { useEffect, useState} from 'react';
//current just to test the flashcard  will be replaced with real data later
import { flashcards } from '../data/testData';

//when APi is complete
const urlBase = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

interface Flashcard{
    id: number;
    term: string;
    definition: string;
}


function Flashcards() {
    const [cards, setCards] = useState<Flashcard[]>([]);
    const [index, setIndex] = useState(0); //what card we are on
    const [showDef, setShowDef] = useState(false); //whether to show term or the definition
    const [sessionComplete, setsessionComplete] = useState(false); //if all the cards have been gone through
    const [knownCards, setKnownCards] = useState<Set<number>>(new Set()); //if the user knows a card
    const [apiLoading, setApiLoading] = useState(false); //wether the data is being fetched from the API or not
    const [error, setError] = useState(""); //error messsage is something goes wrong

    //when API is ready
    //fetch cards from API
    useEffect(() =>{
        const useMockData = true; //change to false when API is ready
        //test code before API is ready
        if (useMockData) {
            setCards(flashcards);
            return;
        }

        setApiLoading(true);
        // Grab setId from URL params, e.g. /flashcards?setId=3
        const params = new URLSearchParams(window.location.search);
        const setId = params.get('setId') || '1';

        const xhr = new XMLHttpRequest();
        xhr.open('GET', `${urlBase}/sets/${setId}/cards`, true);
        xhr.setRequestHeader('Content-type', 'application/json; charset=UTF-8');

        try {
            xhr.onreadystatechange = function (){
                if (this.readyState === 4){
                    if (this.status === 200){
                        const jsonObject = JSON.parse(xhr.responseText);

                        // Expecting { flashcards: [...] } from the server
                        if (!jsonObject.flashcards || jsonObject.flashcards.length === 0){
                            setError('No flashcards in this set.');
                            setApiLoading(false);
                            return;
                        }

                        setCards(jsonObject.flashcards);
                        setApiLoading(false);
                    }else{
                        setError('Failed to load flashcards. Please try again.');
                        setApiLoading(false);
                    }
                }
            };
            xhr.send();
        } catch (err: any){
            setError(err.message);
            setApiLoading(false);
        }
    }, []);

    //flip card
    const toggleCard = () => {
        setShowDef((prev) => !prev);
    }

    //next cards
    const nextCard = () => {
        setShowDef(false);
        setIndex((prev) => (prev + 1) % cards.length);
    };

    //previous card
    const prevCard = () => {
        setShowDef(false);
        setIndex((prev) => (prev - 1 + cards.length) % cards.length);
    };

    //mark card as known
    const markKnown = () =>{
        setKnownCards(prev => new Set(prev).add(cards[index].id));
        nextCard();
    }

    //mark card as unknown
    const markUnknown = () => {
        setKnownCards(prev => {
            const next = new Set(prev);
            next.delete(cards[index].id);
            return next;
        });
        nextCard();
    };

    //restart study session
    const restartSession = () => {
        setIndex(0);
        setShowDef(false);
        setKnownCards(new Set());
        setsessionComplete(false);
    }

    //loading
    if(apiLoading){
        return <h2> Flashcards are Loading...</h2>;
    }

    //error
    if(error){
        return <h2> Error</h2>;
    }

    //session complete screen
    if (sessionComplete){
        return(
            <div className="flashcardContainer">
                <h1>Session Complete</h1>
                <p>
                    You knew {knownCards.size} out of {cards.length} cards!
                </p>
                <button onClick={restartSession}>Restart Set</button>
            </div>
        );
    }
    const currentCard = cards[index];

    //keyboard shortcuts
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'ArrowRight') {
                nextCard();
            } else if (e.key === 'ArrowLeft') {
                prevCard();
            } else if (e.key === ' ' || e.key === 'Enter') {
                e.preventDefault(); // Prevent page scrolling
                toggleCard();
            }
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => {
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, [index, cards, showDef]);

    return(
        <div className="flashcardContainer">
            <h1>Flashcards</h1>
            <p>
                Card {index + 1} of {cards.length}
            </p>
            <div className="flashcard" onClick={toggleCard}>
                <h2>
                    {showDef ? currentCard.definition : currentCard.term}
                </h2>
                <p>Click to flip</p>
            </div>
            <div className="button-group">
                <button onClick={prevCard}>Previous</button>
                <button onClick={nextCard}>Next</button>
                <button onClick={toggleCard}>Flip</button>
            </div>
            <div className="knowldge-buttons">
                <button onClick={markKnown}>I know this </button>
                <button onClick ={markUnknown}> Still Learning</button>
            </div>
        </div>
    );
}
export default Flashcards;

