export interface PersonaSummary {
  id: string;
  name: string;
  model_id: string;
  temperature: number;
}

export interface ChatResponse {
  answer: string;
  persona_id: string;
  model_id: string;
  sources: string[];
}

export interface HealthResponse {
  status: string;
  ollama: boolean;
  database: boolean;
  ollama_url: string;
}

export interface DocumentUploadResponse {
  filename: string;
  chunks_indexed: number;
  message: string;
}

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
  sources?: string[];
}
