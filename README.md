# Field Notes · Reflection

A personal, two-stage reflection tool built as a single-file installable PWA.

1. **Capture** — jot quick field notes (title, ≤500-word body, one of five categories). Mobile-first.
2. **Weekly** — distill notes into reflection *outputs*: link the notes that fed each one, tag output categories, add next steps. The note-linker only shows notes you *haven't* reflected on yet (linked notes drop off the list, and show a "✓ reflected" badge back on Capture), so it doubles as a to-do list of what's left. You can also turn a single note straight into an output with **⤴ Make into output** on any note card.
3. **Outputs** — filter/sort your outputs by category and creation date; open any for full detail + linked notes.
4. **Next Steps** — review every next step across outputs; open one to append follow-up notes.

No build step. One `index.html` holds the whole app; data lives in your browser (`localStorage`) and, once configured, syncs across devices via Supabase.

## Run it locally
Open `index.html` in a browser, or serve the folder:
```bash
cd reflection-tool
python3 -m http.server 8080
# then open http://localhost:8080
```
It runs immediately in **This-device** mode (localStorage) — no account needed.

## Enable phone ↔ desktop sync (Supabase)
Cloud sync is a config toggle. Steps 1–3 need you (accounts can't be created for you); the app does the rest.

1. **Create a free project** at [supabase.com](https://supabase.com) → New project.
2. **Create the tables**: open the project's **SQL Editor**, paste the contents of
   [`supabase-schema.sql`](supabase-schema.sql), and run it. This creates the tables + Row-Level
   Security so only your signed-in account can read your rows.
3. **Enable email auth**: Authentication → Providers → Email → enable. (Magic link is passwordless —
   no password is ever entered into the app.)
4. **Wire up the app**: in `index.html`, fill in the `CONFIG` block near the top of the `<script>`:
   ```js
   const CONFIG = {
     SUPABASE_URL: "https://YOUR-PROJECT.supabase.co",
     SUPABASE_ANON_KEY: "YOUR-ANON-PUBLIC-KEY",
   };
   ```
   Find both under **Project Settings → API**. Save and reload — the badge flips to **☁ Cloud sync**
   and you'll get a magic-link sign-in. Use the same login on phone and desktop and your notes follow you.

Offline writes are queued in the browser and flushed automatically when you reconnect.

## Install as an app (PWA)
Serve the folder over **https** (e.g. GitHub Pages), open it on your phone/desktop, and use
"Add to Home Screen" / "Install". The install option and offline mode only appear over https, not
when opening the file directly.

## Data model (see `supabase-schema.sql`)
- `field_notes` — id, title, content, category, tags[], created_at
- `outputs` — id, title, content, categories[], created_at
- `output_note_links` — output_id ⇄ field_note_id (many-to-many)
- `next_steps` — id, output_id, text, created_at
- `next_step_followups` — id, next_step_id, text, created_at

Week/date labels are derived from `created_at` (ISO week), so nothing is entered by hand.

## Notes on scope (v1)
- Next steps are a **notes-only log** (append follow-ups; no done/dropped status).
- Field-note category is single-select; output categories are multi-select.
- Title 10–15 words is a soft target (counter warns); body word limits are hard caps (500 words for both notes and outputs).
