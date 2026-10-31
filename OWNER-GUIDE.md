# 99 Cafe — owner handover

## Activation status

The database is installed and all 52 menu items are imported. The public website reads the shared menu from Supabase. WhatsApp checkout remains available at 01735603989 while owner activation is pending. The configuration deliberately has onlineOrders: false, and database order intake is paused.

## Remaining activation

1. In Supabase Authentication > Users, create the owner's email/password user privately.
2. Grant that specific trusted owner access using the commented SQL at the end of backend.sql, replacing OWNER_EMAIL. Signing up alone never grants admin access.
3. Sign in at /admin.html. Check restaurant details and delivery fees. Test price edits in both menu views, sold-out controls, and photo upload/removal.
4. Publish cafe-config.js with onlineOrders: true and enable accepting orders in Restaurant settings when staff are ready.
5. Place a clearly labelled test order. Click Enable order alerts, verify the repeating sound and all order statuses before opening intake to customers.

Database validation passed: anonymous order reads and menu writes are blocked, altered prices are rejected, server totals are correct, and repeated request IDs do not duplicate orders. Tests were rolled back; zero test orders remain. Authenticated owner editing and browser alerts still require owner login and end-to-end testing. There are no default passwords or hidden backdoors.

For a fresh project, run backend.sql, seed the menu through the admin import, and configure the public URL/publishable key. Never publish a secret/service-role key.

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
