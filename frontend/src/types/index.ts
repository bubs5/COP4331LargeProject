//structure for ts files

export interface StudySet {
    id: string;
    title: string;
    description: string;
    cardCount: number;
    createdAt?: string;
    updatedAt?: string;
}

export interface Flashcard {
    id: number;
    term: string;
    definition: string;
    setId: string;
}