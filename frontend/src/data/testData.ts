export const studySets = [
    { id: '1', title: 'test 1', description: 'Intro terms', cardCount: 10 },
    { id: '2', title: 'test 2', description: 'middle terms', cardCount: 15 },
    { id: '3', title: 'test 3', description: 'expert terms', cardCount: 12 }
];

export interface Flashcard {
    id: number;
    term: string;
    definition: string;
}

export const flashcards: Flashcard[] = [
    {
        id: 1,
        term: "Who won UWCL in 2024?",
        definition: "Barca"
    },
    {
        id: 2,
        term: "Who won UWCL in 2023?",
        definition: "Barca"
    },
    {
        id: 3,
        term: "Who won the womens Ballon d'Or in 2023?",
        definition: "Bonmati"
    }
];