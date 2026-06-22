create extension if not exists vector with schema extensions;

create table if not exists public.document_chunks (
  id bigserial primary key,
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  embedding extensions.vector(768) not null,
  created_at timestamptz not null default now()
);

create index if not exists document_chunks_embedding_hnsw_idx
  on public.document_chunks
  using hnsw (embedding extensions.vector_cosine_ops);

create index if not exists document_chunks_metadata_source_idx
  on public.document_chunks ((metadata->>'source'));

alter table public.document_chunks enable row level security;
