// Shared species content + art generation, used by both parse-screenshot
// (single-bird flow) and enrich-catches (bulk backfill). The bird_species
// table is a shared cache: once a species is generated, every user reuses it.
import Anthropic from 'npm:@anthropic-ai/sdk';
import { SupabaseClient } from 'npm:@supabase/supabase-js@2';

const HAIKU = 'claude-haiku-4-5-20251001';

export function stripMarkdown(text: string): string {
  return text
    .replace(/^```(?:json|svg|xml)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
}

function textOf(resp: { content: Array<{ type: string; text?: string }> }): string {
  return resp.content[0]?.type === 'text' ? (resp.content[0].text ?? '') : '';
}

const CONTENT_PROMPT = (speciesName: string, scientificName: string) =>
  `You are writing flavor text and stats for a bird trading card game.
For the species "${speciesName}" (${scientificName}), return a JSON object with exactly these keys:

- description: 2–3 sentence natural description of the bird's appearance and behavior (string)
- facts: array of 3 short field-note facts about this species, each under 15 words (string[])
- migration_speed: integer 1–10 representing how fast this species migrates (10 = fastest long-distance migrators like Arctic Tern) (int)
- endurance: integer 1–5 representing stamina in flight (5 = exceptional like albatross) (int)

Return only valid JSON. No explanation or markdown.`;

const SVG_PROMPT = (speciesName: string, scientificName: string) =>
  `Create a minimalist SVG illustration of a ${speciesName} (${scientificName}) for a bird trading card.

Use ONLY these SVG primitives — no <path> elements with complex d= data:
  <ellipse>  for body, head, wing
  <circle>   for eye
  <polygon>  for beak, tail fan
  <line>     for legs, perch, simple markings

Layout (bird facing right, perched on a branch):
  - Body:   <ellipse cx="100" cy="118" rx="48" ry="26"> — adjust rx/ry for species body shape
  - Head:   <ellipse cx="148" cy="95" rx="22" ry="20"> — adjust size/position
  - Beak:   <polygon> triangle pointing right from head
  - Tail:   <polygon> fan or wedge extending left from body
  - Wing:   <ellipse> slightly smaller than body, overlaid
  - Eye:    <circle r="4" fill="#38618C">
  - Legs:   two <line> elements down from body
  - Perch:  <line x1="60" y1="148" x2="145" y2="148">

Styling:
  - All elements except eye: fill="none" stroke="#38618C" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"
  - Eye: fill="#38618C" stroke="none"
  - If the species has a distinctive crest, add a small <polygon> on top of the head
  - If it has a colour patch or wing bar, add a short <line> or small <ellipse> with fill="#38618C" opacity="0.3"

Canvas: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">

Output ONLY the SVG. Start immediately with <svg and end with </svg>. No markdown, no code fences, no comments.`;

const GEO_PROMPT = (location: string) =>
  `Return a JSON object with the decimal latitude and longitude of "${location}", or null for each if the location is ambiguous or unknown.
Keys: "latitude" (float | null), "longitude" (float | null).
Return only valid JSON. No explanation or markdown.`;

export interface SpeciesContent {
  description: string;
  facts: string[];
  migration_speed: number;
  endurance: number;
  line_art_url: string | null;
}

/// Resolves a species' card content + line art, generating and caching it in
/// bird_species on a cache miss. [supabase] must be the service-role client
/// (writes the shared cache + storage).
export async function ensureSpeciesContent(
  anthropic: Anthropic,
  supabase: SupabaseClient,
  speciesName: string,
  scientificName: string,
): Promise<SpeciesContent> {
  const { data: cached } = await supabase
    .from('bird_species')
    .select('description, facts, migration_speed, endurance, line_art_url')
    .eq('species_name', speciesName)
    .maybeSingle();
  if (cached && cached.description) {
    return {
      description: cached.description,
      facts: cached.facts ?? [],
      migration_speed: cached.migration_speed ?? 5,
      endurance: cached.endurance ?? 3,
      line_art_url: cached.line_art_url ?? null,
    };
  }

  const [contentResponse, svgResponse] = await Promise.all([
    anthropic.messages.create({
      model: HAIKU,
      max_tokens: 512,
      messages: [{ role: 'user', content: CONTENT_PROMPT(speciesName, scientificName) }],
    }),
    anthropic.messages.create({
      model: HAIKU,
      max_tokens: 2048,
      messages: [{ role: 'user', content: SVG_PROMPT(speciesName, scientificName) }],
    }),
  ]);

  const content = JSON.parse(stripMarkdown(textOf(contentResponse)));
  const description = content.description as string;
  const facts = content.facts as string[];
  const migration_speed = content.migration_speed as number;
  const endurance = content.endurance as number;

  let line_art_url: string | null = null;
  const svg = stripMarkdown(textOf(svgResponse));
  if (svg.startsWith('<svg')) {
    const slug = speciesName.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    const path = `line-art/${slug}.svg`;
    const { error } = await supabase.storage
      .from('screenshots')
      .upload(path, new TextEncoder().encode(svg), { contentType: 'image/svg+xml', upsert: true });
    if (!error) {
      line_art_url = supabase.storage.from('screenshots').getPublicUrl(path).data.publicUrl;
    }
  }

  await supabase.from('bird_species').upsert({
    species_name: speciesName,
    scientific_name: scientificName,
    description,
    facts,
    migration_speed,
    endurance,
    line_art_url,
  }, { onConflict: 'species_name', ignoreDuplicates: true });

  return { description, facts, migration_speed, endurance, line_art_url };
}

/// Geocodes a free-text location to lat/long via Haiku, or null on ambiguity.
export async function geocodeLocation(
  anthropic: Anthropic,
  location: string,
): Promise<{ latitude: number | null; longitude: number | null }> {
  if (!location) return { latitude: null, longitude: null };
  try {
    const geoResponse = await anthropic.messages.create({
      model: HAIKU,
      max_tokens: 128,
      messages: [{ role: 'user', content: GEO_PROMPT(location) }],
    });
    const geo = JSON.parse(stripMarkdown(textOf(geoResponse)));
    return { latitude: geo.latitude ?? null, longitude: geo.longitude ?? null };
  } catch {
    return { latitude: null, longitude: null };
  }
}

/// Resolves a date string to its most recent past occurrence — Merlin's list
/// header often omits the year (e.g. "June 21"), so a model may stamp it with
/// the current year and push it into the future. ISO date string in/out.
export function resolvePastDate(dateStr: string): string {
  const parsed = new Date(dateStr + 'T00:00:00Z');
  const today = new Date();
  today.setUTCHours(23, 59, 59, 999);
  if (parsed.getTime() > today.getTime()) {
    parsed.setUTCFullYear(parsed.getUTCFullYear() - 1);
  }
  return parsed.toISOString().slice(0, 10);
}
