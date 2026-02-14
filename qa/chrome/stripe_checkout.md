# Stripe Checkout QA (SOP)
**Target:** `http://localhost:5000` | **Environment:** Stripe Test Mode

## 🧪 Test Case: Pro Tier Subscription
### Steps
1. **Selection:** Navigate to `/pricing`. Click the "Subscribe" button under the **Pro** tier.
2. **Redirect:** Verify the browser redirects to `checkout.stripe.com`.
3. **Payment Details:**
   - **Email:** `qa-test-${timestamp}@example.com`
   - **Card:** Use Stripe Test Card `4242 4242 4242 4242`
   - **Expiry/CVC:** Any future date and `123`.
4. **Processing:** Click "Pay" and wait for the "Processing" spinner to finish.
5. **Validation:** After redirect back to the app, wait 3-5 seconds (for Webhook processing).

## 🏁 Expected Results (Checkpoints)
- [ ] Redirected back to `/success` or `/profile`.
- [ ] Database check: `subscription_status` in Supabase is "active".
- [ ] UI check: `EText.proBadge` is visible on the dashboard.
- [ ] GetX state: `isPremium.value` is `true`.

## 🛑 Failure Criteria
- Stuck on Stripe Checkout (invalid test card).
- Redirected to `/failure` or back to `/pricing`.
- Database still shows "free" status after 10 seconds (Webhook failure).