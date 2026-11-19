// Настройки календаря. Заполни два поля из Supabase:
// Project Settings → API (или Data API): Project URL и anon public key.
// anon-ключ публичный, его можно держать в коде. service_role сюда НЕ вставлять!
window.CALENDAR_CONFIG = {
  SUPABASE_URL: 'https://ndulwatdbmnwsfykqxsa.supabase.co',        // например https://abcdefgh.supabase.co
  SUPABASE_ANON_KEY: 'sb_publishable_K4m9aM8RdWsYubS5XvJ9JQ_TDEeIzkF', // publishable (или старый anon eyJ...)
  BUCKET: 'calendar',        // хранилище для картинок (создаётся SQL-скриптом)
  YEAR: 2027                 // год календаря
};
