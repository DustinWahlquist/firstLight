import Anthropic from 'npm:@anthropic-ai/sdk';
import { createClient } from 'npm:@supabase/supabase-js@2';
import { ensureSpeciesContent } from '../_shared/species_content.ts';

// Backfill for "log now, enrich later": after a bulk log creates cards with
// placeholder content, this generates (or reuses the cached) flavor text +
// art per new species and writes it onto the caller's just-created cards.
// bird_cards has no client UPDATE policy, so the write is service-role and
// scoped to the caller's id (read from their JWT).
const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });
const service = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 });
  }
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 });
  }

  const { species = [] } = await req.json();
  const list = (Array.isArray(species) ? species : []) as Array<{
    species_name: string;
    scientific_name?: string;
  }>;

  let enriched = 0;
  await Promise.all(list.map(async (s) => {
    if (!s.species_name) return;
    try {
      const content = await ensureSpeciesContent(
        anthropic,
        service,
        s.species_name,
        s.scientific_name ?? '',
      );
      await service.from('bird_cards').update({
        description: content.description,
        facts: content.facts,
        migration_speed: content.migration_speed,
        endurance: content.endurance,
        line_art_url: content.line_art_url,
      }).eq('user_id', user.id).eq('species_name', s.species_name);
      enriched++;
    } catch (_) {
      // Best-effort: a single species failing shouldn't sink the batch.
    }
  }));

  return new Response(JSON.stringify({ enriched }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
