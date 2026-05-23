import Anthropic from 'npm:@anthropic-ai/sdk';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

const SYSTEM_PROMPT = `You are parsing a screenshot from the Merlin Bird ID app.
Extract information and return a JSON object with exactly these keys:

- species_name: common name of the bird (string)
- scientific_name: Latin name (string)
- rarity: card rarity tier — one of "Common", "Somewhat Rare", or "Ultra Rare" (string)
- sighting_rarity: rarity of this specific sighting — one of "Common", "Uncommon", or "Rare" (string)
- date: date of sighting, ISO 8601 YYYY-MM-DD (string)
- location: location name from the screenshot (string)
- description: 2–3 sentence natural description of the bird's appearance and behavior (string)
- facts: array of 3 short field-note facts about this species (string[])
- migration_speed: integer 1–10 representing how fast this species migrates (int)
- endurance: integer 1–5 representing how many consecutive days this bird can fly without rest (int)

Return only valid JSON. No explanation or markdown.`;

Deno.serve(async (req) => {
  const { image } = await req.json();

  const response = await anthropic.messages.create({
    model: 'claude-opus-4-7',
    max_tokens: 512,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: { type: 'base64', media_type: 'image/jpeg', data: image },
          },
          { type: 'text', text: 'Parse this Merlin Bird ID screenshot.' },
        ],
      },
    ],
    system: SYSTEM_PROMPT,
  });

  const text = response.content[0].type === 'text' ? response.content[0].text : '';

  try {
    const parsed = JSON.parse(text);
    return new Response(JSON.stringify(parsed), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch {
    return new Response(JSON.stringify({ error: 'Failed to parse response', raw: text }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
