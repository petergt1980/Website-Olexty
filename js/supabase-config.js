const SUPABASE_URL = "https://kpqzqnjzqguaornklipt.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_t5u-Mawhf5HBTPmw4DMMgQ_8s2Mmtdh";
window.supabaseClient = null;
window.SUPABASE_READY = false;
if (window.supabase && SUPABASE_URL.startsWith("https://") && !SUPABASE_URL.includes("ISI_URL") && SUPABASE_ANON_KEY && !SUPABASE_ANON_KEY.includes("ISI_ANON")) {
  window.supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  window.SUPABASE_READY = true;
}
