"use client";

import { useEffect, useRef, useState } from "react";

import {
  fetchHealth,
  fetchPersonas,
  sendChat,
  uploadDocument,
} from "@/lib/api";
import type { ChatMessage, PersonaSummary } from "@/types";

export default function ChatApp() {
  const [personas, setPersonas] = useState<PersonaSummary[]>([]);
  const [personaId, setPersonaId] = useState("default");
  const [useRag, setUseRag] = useState(true);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [health, setHealth] = useState<string>("checking...");
  const [error, setError] = useState<string | null>(null);
  const [uploadStatus, setUploadStatus] = useState<string | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    async function init() {
      try {
        const [healthRes, personaList] = await Promise.all([
          fetchHealth(),
          fetchPersonas(),
        ]);
        setHealth(
          healthRes.ollama && healthRes.database
            ? "Ollama + Supabase 연결됨"
            : healthRes.ollama
              ? "Ollama 연결됨 · Supabase 미연결 (DATABASE_URL 확인)"
              : "Ollama 미연결 — ollama serve 확인",
        );
        setPersonas(personaList);
        if (personaList.length > 0) {
          setPersonaId(personaList[0].id);
        }
      } catch (err) {
        setHealth("백엔드 연결 실패");
        setError(err instanceof Error ? err.message : "초기화 실패");
      }
    }

    init();
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, loading]);

  async function handleSend() {
    const text = input.trim();
    if (!text || loading) return;

    setInput("");
    setError(null);
    setMessages((prev) => [...prev, { role: "user", content: text }]);
    setLoading(true);

    try {
      const response = await sendChat(text, personaId, useRag);
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: response.answer,
          sources: response.sources,
        },
      ]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "요청 실패");
    } finally {
      setLoading(false);
    }
  }

  async function handleUpload(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadStatus("업로드 중...");
    setError(null);

    try {
      const result = await uploadDocument(file);
      setUploadStatus(result.message);
    } catch (err) {
      setUploadStatus(null);
      setError(err instanceof Error ? err.message : "업로드 실패");
    }

    event.target.value = "";
  }

  const selectedPersona = personas.find((p) => p.id === personaId);

  return (
    <div className="mx-auto flex h-screen max-w-4xl flex-col px-4 py-6">
      <header className="mb-4 rounded-2xl border border-zinc-200 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 className="text-xl font-semibold">로컬 LLM 에이전트 MVP</h1>
            <p className="text-sm text-zinc-500">{health}</p>
          </div>
          <div className="flex flex-wrap items-center gap-3 text-sm">
            <label className="flex items-center gap-2">
              <span>페르소나</span>
              <select
                className="rounded-lg border border-zinc-300 bg-white px-2 py-1 dark:border-zinc-700 dark:bg-zinc-800"
                value={personaId}
                onChange={(e) => setPersonaId(e.target.value)}
              >
                {personas.map((persona) => (
                  <option key={persona.id} value={persona.id}>
                    {persona.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={useRag}
                onChange={(e) => setUseRag(e.target.checked)}
              />
              RAG 사용
            </label>
            <label className="cursor-pointer rounded-lg border border-zinc-300 px-3 py-1 hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-800">
              문서 업로드 (.txt, .md)
              <input
                type="file"
                accept=".txt,.md"
                className="hidden"
                onChange={handleUpload}
              />
            </label>
          </div>
        </div>
        {selectedPersona && (
          <p className="mt-2 text-xs text-zinc-500">
            모델: {selectedPersona.model_id} · temperature:{" "}
            {selectedPersona.temperature}
          </p>
        )}
        {uploadStatus && (
          <p className="mt-2 text-xs text-emerald-600">{uploadStatus}</p>
        )}
      </header>

      <main className="flex-1 overflow-y-auto rounded-2xl border border-zinc-200 bg-zinc-50 p-4 dark:border-zinc-800 dark:bg-zinc-950">
        {messages.length === 0 && (
          <p className="text-sm text-zinc-500">
            문서를 업로드한 뒤 질문해 보세요. 예: &quot;이 프로젝트의 기술
            스택은?&quot;
          </p>
        )}
        <div className="space-y-4">
          {messages.map((message, index) => (
            <div
              key={`${message.role}-${index}`}
              className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-6 ${
                message.role === "user"
                  ? "ml-auto bg-blue-600 text-white"
                  : "bg-white text-zinc-900 shadow-sm dark:bg-zinc-900 dark:text-zinc-100"
              }`}
            >
              <p className="whitespace-pre-wrap">{message.content}</p>
              {message.sources && message.sources.length > 0 && (
                <p className="mt-2 text-xs opacity-70">
                  출처: {message.sources.join(", ")}
                </p>
              )}
            </div>
          ))}
          {loading && (
            <div className="max-w-[85%] rounded-2xl bg-white px-4 py-3 text-sm text-zinc-500 shadow-sm dark:bg-zinc-900">
              응답 생성 중...
            </div>
          )}
          <div ref={bottomRef} />
        </div>
      </main>

      {error && (
        <p className="mt-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950 dark:text-red-300">
          {error}
        </p>
      )}

      <footer className="mt-4 flex gap-2">
        <input
          className="flex-1 rounded-xl border border-zinc-300 bg-white px-4 py-3 text-sm outline-none focus:border-blue-500 dark:border-zinc-700 dark:bg-zinc-900"
          placeholder="메시지를 입력하세요..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              handleSend();
            }
          }}
          disabled={loading}
        />
        <button
          type="button"
          onClick={handleSend}
          disabled={loading || !input.trim()}
          className="rounded-xl bg-blue-600 px-5 py-3 text-sm font-medium text-white disabled:opacity-50"
        >
          전송
        </button>
      </footer>
    </div>
  );
}
