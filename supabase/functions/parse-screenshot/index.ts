import Anthropic from 'npm:@anthropic-ai/sdk';
import { createClient } from 'npm:@supabase/supabase-js@2';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const VISION_PROMPT = `You are parsing a screenshot from the Merlin Bird ID app.
Extract only what is visible in the screenshot and return a JSON object with exactly these keys:

- species_name: common name of the bird (string)
- scientific_name: Latin name (string)
- rarity: card rarity tier — one of "Common", "Somewhat Rare", or "Ultra Rare" (string)
- sighting_rarity: rarity of this specific sighting — one of "Common", "Uncommon", or "Rare" (string)
- date: date of sighting, ISO 8601 YYYY-MM-DD (string)
- location: location name from the screenshot (string)

Return only valid JSON. No explanation or markdown.`;

const CONTENT_PROMPT = (speciesName: string, scientificName: string, location: string) =>
  `You are writing flavor text for a bird trading card game and geocoding a location.
For the species "${speciesName}" (${scientificName}) sighted at "${location}", return a JSON object with exactly these keys:

- description: 2–3 sentence natural description of the bird's appearance and behavior (string)
- facts: array of 3 short field-note facts about this species, each under 15 words (string[])
- migration_speed: integer 1–10 representing how fast this species migrates (10 = fastest long-distance migrators like Arctic Tern) (int)
- endurance: integer 1–5 representing stamina in flight (5 = exceptional like albatross) (int)
- latitude: decimal latitude of the location "${location}" as a float, or null if unknown (float | null)
- longitude: decimal longitude of the location "${location}" as a float, or null if unknown (float | null)

Return only valid JSON. No explanation or markdown.`;

const GEO_PROMPT = (location: string) =>
  `Return a JSON object with the decimal latitude and longitude of "${location}", or null for each if the location is ambiguous or unknown.
Keys: "latitude" (float | null), "longitude" (float | null).
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

function stripMarkdown(text: string): string {
  return text
    .replace(/^```(?:json|svg|xml)?\s*/i, '')
    .replace(/\s*```$/, '')
    .trim();
}

Deno.serve(async (req) => {
  const { image, media_type = 'image/jpeg' } = await req.json();

  // Step 1: Haiku extracts factual fields from the image
  const visionResponse = await anthropic.messages.create({
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 256,
    system: VISION_PROMPT,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: media_type as 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp', data: image },
          },
          { type: 'text', text: 'Parse this Merlin Bird ID screenshot.' },
        ],
      },
    ],
  });

  const visionText = visionResponse.content[0].type === 'text' ? visionResponse.content[0].text : '';
  let sighting: Record<string, unknown>;
  try {
    sighting = JSON.parse(stripMarkdown(visionText));
  } catch {
    return new Response(JSON.stringify({ error: 'Vision parse failed', raw: visionText }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const speciesName = sighting.species_name as string;
  const scientificName = sighting.scientific_name as string;
  const location = sighting.location as string;

  // Step 2: Check shared species cache
  const { data: cached } = await supabase
    .from('bird_species')
    .select('*')
    .eq('species_name', speciesName)
    .maybeSingle();

  let description: string;
  let facts: string[];
  let migrationSpeed: number;
  let endurance: number;
  let lineArtUrl: string | null = null;
  let latitude: number | null = null;
  let longitude: number | null = null;

  if (cached) {
    // Use cached species content, geocode location separately
    description = cached.description;
    facts = cached.facts;
    migrationSpeed = cached.migration_speed;
    endurance = cached.endurance;
    lineArtUrl = cached.line_art_url;

    const geoResponse = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 128,
      messages: [{ role: 'user', content: GEO_PROMPT(location) }],
    });
    const geoText = geoResponse.content[0].type === 'text' ? geoResponse.content[0].text : '';
    try {
      const geo = JSON.parse(stripMarkdown(geoText));
      latitude = geo.latitude ?? null;
      longitude = geo.longitude ?? null;
    } catch { /* leave null */ }
  } else {
    // Generate content + line art in parallel with Haiku
    const [contentResponse, svgResponse] = await Promise.all([
      anthropic.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 512,
        messages: [{ role: 'user', content: CONTENT_PROMPT(speciesName, scientificName, location) }],
      }),
      anthropic.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 2048,
        messages: [{ role: 'user', content: SVG_PROMPT(speciesName, scientificName) }],
      }),
    ]);

    // Parse content
    const contentText = contentResponse.content[0].type === 'text' ? contentResponse.content[0].text : '';
    let content: Record<string, unknown>;
    try {
      content = JSON.parse(stripMarkdown(contentText));
    } catch {
      return new Response(JSON.stringify({ error: 'Content generation failed', raw: contentText }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
    description = content.description as string;
    facts = content.facts as string[];
    migrationSpeed = content.migration_speed as number;
    endurance = content.endurance as number;
    latitude = (content.latitude as number | null) ?? null;
    longitude = (content.longitude as number | null) ?? null;

    // Upload SVG line art
    const svgText = svgResponse.content[0].type === 'text' ? svgResponse.content[0].text : '';
    const svg = stripMarkdown(svgText);
    if (svg.startsWith('<svg')) {
      const slug = speciesName.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
      const path = `line-art/${slug}.svg`;
      const svgBytes = new TextEncoder().encode(svg);
      const { error: uploadError } = await supabase.storage
        .from('screenshots')
        .upload(path, svgBytes, { contentType: 'image/svg+xml', upsert: true });
      if (!uploadError) {
        lineArtUrl = supabase.storage.from('screenshots').getPublicUrl(path).data.publicUrl;
      }
    }

    // Cache in bird_species (ignore conflicts — another request may have raced us)
    await supabase.from('bird_species').upsert({
      species_name: speciesName,
      scientific_name: scientificName,
      rarity: sighting.rarity,
      description,
      facts,
      migration_speed: migrationSpeed,
      endurance,
      line_art_url: lineArtUrl,
    }, { onConflict: 'species_name', ignoreDuplicates: true });
  }

  return new Response(JSON.stringify({
    ...sighting,
    description,
    facts,
    migration_speed: migrationSpeed,
    endurance,
    latitude,
    longitude,
    line_art_url: lineArtUrl,
  }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
