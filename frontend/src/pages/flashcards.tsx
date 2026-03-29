import { useState } from 'react';
//current just to test the flashcard  will be replaced with real data later
import { flashcards } from '../data/testData';


function Flashcards() {
    //if setis empty
    if (flashcards.length === 0) {
        return <p>No flashcards available.</p>;
    }
    //what card we are on
    const [index, setIndex] = useState(0);
    const [showDef, setShowDef] = useState(false);

    //next cards
    const nextCard = () => {
        setShowDef(false);
        setIndex((prev) => (prev + 1) % flashcards.length);
    };

    //previous card
    const prevCard = () => {
        setShowDef(false);
        setIndex((prev) => (prev - 1 + flashcards.length) % flashcards.length);
    };

    const toggleCard = () => {
        setShowDef((prev) => !prev)
    };

    return(
        <div>
            <h1>Flashcards</h1>
            <div className="flashcard" onClick={toggleCard}>
                <h2>
                    {showDef ? flashcards[index].definition : flashcards[index].term}
                </h2>
            </div>
            <div className="button-group">
                <button onClick={prevCard}>Previous</button>
                <button onClick={nextCard}>Next</button>
                <button onClick={toggleCard}>Flip</button>
            </div>
        </div>
    );
}
export default Flashcards;


