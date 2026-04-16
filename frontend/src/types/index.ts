// structure for ts files

export interface StudySet {
    id: string;
    title: string;
    description: string;
    cardCount: number;
    createdAt?: string;
    updatedAt?: string;
}

export interface Flashcard {
    id: string;
    term: string;
    definition: string;
    setId: string;
}

export interface UserData {
    id: string;
    firstName: string;
    lastName: string;
    username: string;
    token: string;
}
