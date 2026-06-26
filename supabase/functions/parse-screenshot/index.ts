import Anthropic from 'npm:@anthropic-ai/sdk';
import { createClient } from 'npm:@supabase/supabase-js@2';
import {
  ensureSpeciesContent,
  geocodeLocation,
  resolvePastDate,
  stripMarkdown,
} from '../_shared/species_content.ts';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// One vision call classifies the screenshot and transcribes it. We use a
// stronger model here than for content generation: a list screen needs many
// rows transcribed and the blue "verified" checkmark told apart from the
// gray waveform icon.
const VISION_PROMPT = `You are parsing a screenshot from the Merlin Bird ID app.
You are a transcriber, NOT a bird identifier. Only transcribe text that is
clearly legible. NEVER identify, guess, or infer a species from a bird photo —
if a name's text is covered, cropped, blurred, or absent, treat it as not
visible even if you recognize the bird in the picture.

First decide which kind of screen this is:
- "single": one bird's species or detail view (a single prominent bird name).
- "list": Merlin's "Identify" results — a header with a date and a place, then
  multiple rows, each a bird with a common name, a scientific name, and
  sometimes a small blue circular checkmark badge just after the common name.

Return ONLY valid JSON, no markdown.

If single, return:
{
  "type": "single",
  "name_visible": <boolean: is the common name fully legible as text?>,
  "species_name": <common name exactly as written, or null>,
  "scientific_name": <Latin name as written, or null>,
  "sighting_rarity": "Common" | "Uncommon" | "Rare",
  "date": "YYYY-MM-DD" or null,
  "location": <location text from the screenshot, or null>
}

If list, return:
{
  "type": "list",
  "date": "YYYY-MM-DD" or null,
  "location": <location text from the header, or null>,
  "birds": [
    { "species_name": <common name as written>, "scientific_name": <Latin name or null>, "verified": <boolean> }
  ]
}

For list rows, "verified" is true ONLY when that row clearly shows a small blue
circular checkmark badge next to the common name. Rows without that blue check
are NOT verified — set false. Do NOT treat the gray waveform/spectrogram icon
with a magnifier (far right of each row) as a verification badge.

For dates shown without a year (e.g. "June 21"), still return YYYY-MM-DD using
your best guess of the year; it will be corrected to the most recent past date.`;

function unverifiable(message: string): Response {
  return new Response(JSON.stringify({ error: 'unverifiable', message }), {
    status: 422,
    headers: { 'Content-Type': 'application/json' },
  });
}

function json(body: unknown): Response {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  const { image, media_type = 'image/jpeg' } = await req.json();

  const visionResponse = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 2048,
    system: VISION_PROMPT,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: media_type as 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp',
              data: image,
            },
          },
          { type: 'text', text: 'Parse this Merlin Bird ID screenshot.' },
        ],
      },
    ],
  });

  const visionText = visionResponse.content[0].type === 'text' ? visionResponse.content[0].text : '';
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(stripMarkdown(visionText));
  } catch {
    return new Response(JSON.stringify({ error: 'Vision parse failed', raw: visionText }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // ── Bulk: a Merlin "Identify" list ──
  if (parsed.type === 'list') {
    const birds = Array.isArray(parsed.birds) ? parsed.birds : [];
    if (!parsed.date || !parsed.location) {
      return unverifiable(
        "Couldn't read this list — the date or location isn't clearly visible in the screenshot.",
      );
    }
    if (birds.length === 0) {
      return unverifiable("Couldn't read any birds from this screenshot.");
    }
    return json({
      type: 'list',
      date: resolvePastDate(parsed.date as string),
      location: parsed.location,
      birds: birds.map((b: Record<string, unknown>) => ({
        species_name: b.species_name,
        scientific_name: b.scientific_name ?? '',
        verified: b.verified === true,
      })),
    });
  }

  // ── Single bird: verify the screenshot, then build the full card ──
  const missing: string[] = [];
  if (parsed.name_visible !== true || !parsed.species_name) missing.push("the bird's name");
  if (!parsed.date) missing.push('the sighting date');
  if (missing.length > 0) {
    return unverifiable(
      `Couldn't verify this catch — ${missing.join(' and ')} ` +
        `${missing.length > 1 ? "aren't" : "isn't"} clearly visible in the screenshot.`,
    );
  }

  const speciesName = parsed.species_name as string;
  const scientificName = (parsed.scientific_name as string) ?? '';
  const location = (parsed.location as string) ?? '';

  const [content, geo] = await Promise.all([
    ensureSpeciesContent(anthropic, supabase, speciesName, scientificName),
    geocodeLocation(anthropic, location),
  ]);

  return json({
    type: 'single',
    species_name: speciesName,
    scientific_name: scientificName,
    sighting_rarity: parsed.sighting_rarity ?? 'Common',
    date: resolvePastDate(parsed.date as string),
    location,
    description: content.description,
    facts: content.facts,
    migration_speed: content.migration_speed,
    endurance: content.endurance,
    latitude: geo.latitude,
    longitude: geo.longitude,
    line_art_url: content.line_art_url,
  });
});
