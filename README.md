# Fitly Studio

Fitly Studio is a responsive virtual fashion try-on website concept. The repository currently contains the public landing page, an admin dashboard interface preview, and a Supabase starter schema.

## Pages
- `index.html` — public landing page and interactive front-end demo
- `admin.html` — admin dashboard UI preview (overview, users, products, try-on activity, settings)
- `supabase/schema.sql` — starter database tables and row-level security policies

## Important implementation status
The public try-on flow is currently a front-end demo. It accepts a local photo and lets visitors select a garment colour, but it does **not** generate an AI try-on image. The admin page currently displays sample data and its actions are illustrative; it is **not yet connected to authentication or a live database**.

Do not use the sample admin interface to manage real accounts or customer data. A secure production admin requires backend-enforced authentication and authorization. Hiding a page or adding a client-side password is not security.

## Backend setup
1. Create a Supabase project.
2. Open the Supabase SQL Editor and run `supabase/schema.sql`.
3. Register your account through Supabase Auth.
4. Promote the intended admin account by running the commented SQL at the bottom of the schema, replacing `YOUR_ADMIN_EMAIL` with the account email. Only do this from the trusted SQL Editor.
5. Configure a frontend using the Supabase project URL and the public anon/publishable key. Never put the `service_role` key in browser code.
6. Connect the pages to Supabase Auth and the tables, and add private storage buckets and a server-side AI provider integration before production use.

## Publish the static pages
For a static preview, open the repository's **Settings → Pages**, choose **Deploy from a branch**, select `main` and `/(root)`, then save. GitHub Pages can host the static HTML, but it cannot run the database, authenticate admins by itself, or securely proxy AI requests.

## Before launch
- Implement sign-up, sign-in, sign-out, password reset, and protected admin routing.
- Connect product and user management to the database and enforce admin checks server-side.
- Store user images in private storage with appropriate access and deletion controls.
- Call an AI try-on provider through a server-side function; do not expose provider secrets in the browser.
- Add billing only after a trusted payment provider and server-side webhook verification are implemented.
- Test authorization policies with ordinary and admin accounts.
