// structure for ts files

export interface StudySet {
    id: string;       // mapped from MongoDB _id
    title: string;
    description: string;
    cardCount: number; // computed by the API
    createdAt?: string;
    updatedAt?: string;
}

export interface Flashcard {
    id: string;        // mapped from MongoDB _id (was number, now string)
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
