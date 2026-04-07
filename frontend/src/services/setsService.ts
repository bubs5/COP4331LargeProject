//all fetched come in through this page
import { flashcards as seedCards, studySets as seedSets } from '../data/testData';
import type { Flashcard, StudySet } from '../types';

const SETS_KEY = 'study_sets';
const CARDS_KEY = 'study_cards';
const USE_MOCK_DATA = true; //set to false when api is ready
const urlBase = import.meta.env.VITE_API_URL || 'http://localhost:5000/api'; //replace with api link wen ready

function seedLocalData(){
    if (!localStorage.getItem(SETS_KEY)){
        localStorage.setItem(SETS_KEY, JSON.stringify(seedSets));
    }

    if (!localStorage.getItem(CARDS_KEY)){
        localStorage.setItem(CARDS_KEY, JSON.stringify(seedCards));
    }
}

function readSets(): StudySet[]{
    seedLocalData();
    return JSON.parse(localStorage.getItem(SETS_KEY) || '[]');
}

function writeSets(sets: StudySet[]){
    localStorage.setItem(SETS_KEY, JSON.stringify(sets));
}

function readCards(): Flashcard[]{
    seedLocalData();
    return JSON.parse(localStorage.getItem(CARDS_KEY) || '[]');
}

function writeCards(cards: Flashcard[]){
    localStorage.setItem(CARDS_KEY, JSON.stringify(cards));
}
//gathering study set info
export async function getStudySets(): Promise<StudySet[]>{
    if (USE_MOCK_DATA) {
        return readSets().map((set) => ({
            ...set,
            cardCount: readCards().filter((card) => card.setId === set.id).length,
        }));
    }

    const response = await fetch(`${urlBase}/sets`);
    const data = await response.json();
    return data.studySets;
}

export async function getStudySetById(setId: string): Promise<StudySet | null>{
    if (USE_MOCK_DATA) {
        const set = readSets().find((item) => item.id === setId);
        if (!set) return null;
        return {
            ...set,
            cardCount: readCards().filter((card) => card.setId === set.id).length,
        };
    }

    const response = await fetch(`${urlBase}/sets/${setId}`);
    if (!response.ok) return null;
    const data = await response.json();
    return data.studySet;
}
//creating study set
export async function createStudySet(payload: Pick<StudySet, 'title' | 'description'>): Promise<StudySet>{
    if (USE_MOCK_DATA){
        const sets = readSets();
        const newSet: StudySet = {
            id: Date.now().toString(),
            title: payload.title.trim(),
            description: payload.description.trim(),
            cardCount: 0,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };

        writeSets([newSet, ...sets]);
        return newSet;
    }

    const response = await fetch(`${urlBase}/sets`,{
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    });
    const data = await response.json();
    return data.studySet;
}

//delete studyset
export async function deleteStudySet(setId: string): Promise<void>{
    if (USE_MOCK_DATA) {
        const nextSets = readSets().filter((set) => set.id !== setId);
        const nextCards = readCards().filter((card) => card.setId !== setId);

        writeSets(nextSets);
        writeCards(nextCards);
        return;
    }

    await fetch(`${urlBase}/sets/${setId}`,{
        method: "DELETE",
    });
}

//getting the specific flashcards from each set
export async function getCardsForSet(setId: string): Promise<Flashcard[]>{
    if (USE_MOCK_DATA) {
        return readCards().filter((card) => card.setId === setId);
    }

    const response = await fetch(`${urlBase}/sets/${setId}/cards`);
    const data = await response.json();
    return data.flashcards || [];
}
//creating flashcards for each set
export async function createCardForSet(
    setId: string,
    payload: Pick<Flashcard, 'term' | 'definition'>,
): Promise<Flashcard> {
    if (USE_MOCK_DATA) {
        const cards = readCards();
        const newCard: Flashcard = {
            id: Date.now(),
            setId,
            term: payload.term.trim(),
            definition: payload.definition.trim(),
        };

        writeCards([...cards, newCard]);
        const sets = readSets().map((set) =>
            set.id === setId
                ? {
                    ...set,
                    cardCount: (set.cardCount || 0) + 1,
                    updatedAt: new Date().toISOString(),
                }
                : set,
        );
        writeSets(sets);
        return newCard;
    }

    const response = await fetch(`${urlBase}/sets/${setId}/cards`,{
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    });
    const data = await response.json();
    return data.flashcard;
}
//update set
export async function updateCardInSet(
    cardId: number,
    payload: Pick<Flashcard, 'term' | 'definition'>,
): Promise<Flashcard | null> {
    if (USE_MOCK_DATA) {
        const cards = readCards();
        let updatedCard: Flashcard | null = null;

        const nextCards = cards.map((card) =>{
            if (card.id !== cardId) return card;
            updatedCard = {
                ...card,
                term: payload.term.trim(),
                definition: payload.definition.trim(),
            };
            return updatedCard;
        });

        writeCards(nextCards);
        return updatedCard;
    }

    const response = await fetch(`${urlBase}/cards/${cardId}`,{
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    });
    if (!response.ok) return null;
    const data = await response.json();
    return data.flashcard;
}
//delete flashcard
export async function deleteCardFromSet(cardId: number): Promise<void>{
    if (USE_MOCK_DATA) {
        const cards = readCards();
        const deletedCard = cards.find((card) => card.id === cardId);
        writeCards(cards.filter((card) => card.id !== cardId));

        if (deletedCard) {
            const sets = readSets().map((set) =>
                set.id === deletedCard!.setId
                    ? {
                        ...set,
                        cardCount: Math.max((set.cardCount || 1) - 1, 0),
                        updatedAt: new Date().toISOString(),
                    }
                    : set,
            );
            writeSets(sets);
        }
        return;
    }

    await fetch(`${urlBase}/cards/${cardId}`,{
        method: 'DELETE',
    });
}
