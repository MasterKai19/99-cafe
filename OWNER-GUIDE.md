# 99 Cafe — owner handover

## Activation status

The public website currently uses its original menu and WhatsApp checkout. The admin application and database migration are prepared. **Live dashboard orders and menu editing are not active until the Supabase steps below are complete.** There are no shared default passwords or hidden admin backdoors.

## One-time setup

1. Sign in to Supabase using an account owned by the restaurant. Create a project and store the database password securely. Choose a nearby available region and review the plan limits before enabling paid services.
2. Run `backend.sql` once in that project's SQL Editor. It creates menu, settings, private orders, owner permissions, a photo bucket, and realtime subscriptions.
3. In Authentication, create the owner's email/password user. Use a unique strong password. Do not enable public registration for staff accounts. Configure account recovery email and the production site URL.
4. Run the commented owner-access SQL at the end of `backend.sql`, replacing `OWNER_EMAIL` with that user's actual email. Only trusted owner users should appear in `cafe_admins`. Additional owners can be added the same way. Signing up alone never grants admin access.
5. Put the project's public URL and **publishable (or legacy anon) key** into `cafe-config.js`. NEVER use a secret/service-role key in website files. Keep this configuration change local until step 6 is ready.
6. Test the configured application in staging. Sign in at `/admin.html`, import the original 52 menu items, check restaurant details, delivery fee, and ordering status. Publish the config with all application files only when the seeded database is ready. If enabling the config before seeding, disable accepting orders first and expect an empty menu until import completes.
7. Submit a clearly labelled test order. Check the dashboard, sound, accept/preparing/ready/completed flow, price edits in both menu views, sold-out handling, and photo upload/removal. Cancel the test order afterward. Confirm that a signed-out visitor cannot read `cafe_orders` or write `cafe_menu` through the Supabase API.

Do not call the system production-ready until these end-to-end checks pass against the restaurant's project. This package was syntax-checked and the unconnected website reviewed; the live database and authenticated order workflow require activation testing.

## Daily use

- Open `/admin.html` on a dedicated, trusted restaurant device and sign in. The Supabase session persists and refreshes under the project's session policy. It can still expire or be revoked; no app can promise permanent login.
- Tap **Enable order alerts** after opening the dashboard. Leave the device charging, connected and awake. The app requests a screen wake lock where supported. Sleep, screen lock, browser throttling, muted audio or lost internet can stop alerts.
- New website orders repeat an original chime approximately every four seconds until accepted or cancelled. The dashboard also refreshes orders every 15 seconds and on reconnect. WhatsApp messages do not become dashboard orders.
- Move orders through Accepted → Preparing → Ready → Completed. Contact the customer to confirm acceptance and timing. The website does not process payment, dispatch drivers or send automated confirmation messages.
- Menu edits affect both public menu views. Sold-out items remain visible but cannot be ordered. Uncheck Show on both menus to remove an item from public display without losing its data.
- Upload JPEG, PNG or WebP food photos up to 5 MB. The app resizes photos to at most 1200px before upload. Remove photo removes it from the item; previous storage objects remain for recovery and must be periodically cleaned up in Supabase after checking they are unused.
- Set a flat delivery fee and pause new orders in Restaurant settings. Menu text and prices are stored once, shared by both views. Home-page promotional copy and decorative photos still require a source edit.
- Export the menu periodically. An export is a menu snapshot, not a complete database/storage backup. Use Supabase backups and separately retain uploaded photos. Review retention and storage usage regularly.

## What to hand to the buyer

- Domain/DNS ownership, renewal dates, billing account and recovery email.
- GitHub repository ownership and Vercel project ownership, with deployment instructions.
- Supabase project ownership, individual owner accounts and recovery instructions.
- This guide, all source files, a menu export, original restaurant photos and database backups.
- A short training video covering menu editing, photos, sold-out controls and order acknowledgement.
- Written scope: included features, supported devices, hosting charges, support period, and the price of future feature changes. No website is maintenance-free.

## Useful future upgrades

These are not included in this build: verified online payments with webhook handling, customer order tracking, delivery zones and distance fees, scheduled opening hours, separate restricted kitchen/cashier roles, receipt printer integration, loyalty programs, SMS confirmations and reliable native/push notification delivery while the browser is closed. Add only what the owner actually needs.

## Deployment files

Publish these together at repository root: `index.html`, `storefront.js`, `menu-seed.json`, `cafe-config.js`, `admin.html`, `admin.js`, `admin.css`, `OWNER-GUIDE.md`. Keep `backend.sql` in the handover package; run it in Supabase rather than treating it as a website endpoint. GitHub's existing Vercel integration deploys the public site.

The static convenience copy `99-Cafe-Mobile.html` now uses the adjacent JavaScript and JSON files and should be served over HTTP; it is not a self-contained offline application.

## Security and operations

Customer totals are calculated from database prices inside a restricted server function. Orders preserve their item names/prices at the time they were submitted. Requests use idempotency IDs for safe same-page retries. Avoid refreshing while a submission's result is uncertain; call the restaurant before placing a replacement request.

Anonymous users can read the menu and public restaurant settings, but cannot list customer orders or change menu data. The SQL migration limits repeated orders by phone and overall volume. For a public launch with sustained traffic, add CAPTCHA and edge/IP rate limiting; phone-based limits alone cannot stop determined spam. Review database backups, account security and alert-device health as part of operations.

Implementation references: [Supabase row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security), [database functions](https://supabase.com/docs/guides/database/functions), [realtime](https://supabase.com/docs/guides/realtime/postgres-changes), [storage access control](https://supabase.com/docs/guides/storage/security/access-control).
