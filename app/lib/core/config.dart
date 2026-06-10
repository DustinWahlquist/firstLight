/// Identifies the app to the OpenStreetMap tile server (required by their
/// usage policy). Matches the iOS/Android bundle id, which intentionally
/// still reads murmuration.
const osmUserAgentPackageName = 'com.murmuration.murmuration';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://mlvcppunlcaqzxelwsap.supabase.co',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sdmNwcHVubGNhcXp4ZWx3c2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1NTE3NzQsImV4cCI6MjA5NTEyNzc3NH0.UXFcIqucr8g-JKeFngovGBn7ari5gnnQs4MR3ASyKUg',
);
