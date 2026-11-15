# Community-build payment boundary

These adapters explicitly disable StoreKit purchasing, transaction observation and upgrade-plan retrieval. They never synthesize a successful purchase, price list, subscription or entitlement. The subscription screen visibly explains the limitation; purchase operations throw `CommunityPaymentsUnavailable`.

This keeps optional commerce unavailable while the actual mail SDK and account/session integration are restored. Existing account entitlements are still provided by the real SDK. No payment action, transaction finish, subscription update or revenue telemetry is performed here.

The small value types preserve the app's compile-time UI contracts, including its existing isolated previews/tests. They are not data returned from a payment backend.
