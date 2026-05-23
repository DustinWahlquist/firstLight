import Anthropic from 'npm:@anthropic-ai/sdk@0.27.0';

const client = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

const SYSTEM_PROMPT = `You are a parser for Merlin Bird ID app screenshots.
Extract the following from the screenshot and return valid JSON only — no prose, no markdown fences.

Required fields:
- confident (boolean): true if you can clearly identify this as a Merlin screenshot with a bird species
- species_name (string): common name of the bird exactly as displayed (e.g. "American Robin")
- rarity (string): one of "common", "somewhat_rare", or "ultra_rare" based on the Merlin rarity indicator visible in the screenshot
- location (string | null): location text shown in the screenshot, or null if absent

Optional error field (only when confident is false):
- reason (string): brief explanation of why parsing failed

Example success output:
{"confident":true,"species_name":"American Robin","rarity":"common","location":"Seattle, WA"}

Example failure output:
{"confident":false,"reason":"Image does not appear to be a Merlin Bird ID screenshot."}`;

interface ParsedBird {
  confident: boolean;
  species_name: string;
  rarity: 'common' | 'somewhat_rare' | 'ultra_rare';
  location: string | null;
  reason?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  let screenshotUrl: string;
  try {
    const body = await req.json();
    screenshotUrl = body.screenshot_url;
    if (!screenshotUrl) throw new Error('missing screenshot_url');
  } catch (e) {
    return json({ confident: false, reason: `Bad request: ${e.message}` }, 400);
  }

  try {
    const message = await client.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 256,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: { type: 'url', url: screenshotUrl },
            },
            {
              type: 'text',
              text: 'Parse this Merlin screenshot.',
            },
          ],
        },
      ],
    });

    const text =
      message.content[0].type === 'text' ? message.content[0].text : '';
    const parsed: ParsedBird = JSON.parse(text);
    return json(parsed, 200);
  } catch (e) {
    console.error('parse-screenshot error:', e);
    return json(
      { confident: false, reason: 'Internal error during parsing.' },
      500,
    );
  }
});

function json(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
