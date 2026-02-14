# Auth Flow QA (SOP)
**Target:** `http://localhost:5000` | **Agent:** QA Agent

## 🧪 Test Case 01: Standard Signup & Login
### Steps
1. **Navigate:** Open the web app.
2. **Signup:** Click "Get Started." Enter a random email and password.
3. **Email Verification:** Check for the "Verification Sent" toast. (Note: In local dev, check Supabase logs).
4. **Session Persistence:** Hard-refresh the browser. 
5. **Logout/Login:** Log out via the Profile menu, then log back in.

## 🏁 Expected Results (Checkpoints)
- [ ] URL changes to `/dashboard` after login.
- [ ] GetX `AuthController` state updates to `isAuthenticated = true`.
- [ ] No "403 Forbidden" errors in the Chrome Console.
- [ ] `EText.welcomeMessage` is visible on the screen.

## 🛑 Failure Criteria
- Redirection loop between `/login` and `/`.
- "Invalid Credentials" on a newly created account.