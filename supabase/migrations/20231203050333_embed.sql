-- General purpose trigger function to generate text embeddings
-- on newly inserted rows.
--
-- Calls an edge function at `/embed` in batches that asynchronously
-- generates the embeddings and stores them on each record.
-- 
-- Trigger is expected to have the format:
--
-- create trigger <trigger_name>
-- after insert on <table_name>
-- referencing new table as inserted
-- for each statement
-- execute procedure private.embed(<content_column>, <embedding_column>);
--
-- Expects 3 arguments: `private.embed(<content_column>, <embedding_column>, <batch_size>)`
-- where the first argument indicates the source column containing the text content,
-- the second argument indicates the destination column to store the embedding,
-- and the third argument indicates the number of records to include in each edge function call.
create function private.embed() 
returns trigger 
language plpgsql
as $$
declare
  content_column text = TG_ARGV[0];
  embedding_column text = TG_ARGV[1];
  batch_size int = TG_ARGV[2];
  batch_count int = ceiling((select count(*) from inserted) / batch_size::float);
  result int;
begin

  for i in 0 .. (batch_count-1) loop
  select
    net.http_post(
      url := supabase_url() || '/functions/v1/embed',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', current_setting('request.headers')::json->>'authorization'
      ),
      body := jsonb_build_object(
        'ids', (select json_agg(ds.id) from (select id from inserted limit batch_size offset i*batch_size) ds),
        'table', TG_TABLE_NAME,
        'contentColumn', content_column,
        'embeddingColumn', embedding_column
      )
    )
  into result;
  end loop;

  return null;
end;
$$;

create trigger embed_document_sections
  after insert on document_sections
  referencing new table as inserted
  for each statement
  execute procedure private.embed(content, embedding, 10);
