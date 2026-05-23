import Anthropic from 'npm:@anthropic-ai/sdk';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

const SYSTEM_PROMPT = `You are parsing a screenshot from the Merlin Bird ID app.
Extract the following fields and return them as JSON:
- species_name: the bird's common name (string)
- rarity: one of "Common", "Somewhat Rare", or "Ultra Rare" (string)
- date: the date of the sighting in ISO 8601 format YYYY-MM-DD (string)
- location: the location name shown in the screenshot (string)

Return only valid JSON with these four keys. No explanation.`;

Deno.serve(async (req) => {
  const { image } = await req.json();

  const response = await anthropic.messages.create({
    model: 'claude-opus-4-7',
    max_tokens: 256,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: 'image/jpeg',
              data: image,
            },
          },
          {
            type: 'text',
            text: 'Parse this Merlin Bird ID screenshot.',
          },
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
