# Apple Sign In Implementation Plan

## Goal
Enable "Sign in with Apple" for BingeQuest to comply with App Store Review Guidelines (Guideline 4.8), which require an equivalent privacy-focused login service when third-party logins (like Google) are offered.

## Current Status
- **Dependencies**: `sign_in_with_apple` and `crypto` are present in `pubspec.yaml`.
- **Logic**: `AuthController` (`lib/features/auth/controllers/auth_controller.dart`) already contains `signInWithApple()` logic.
- **UI**: `SignInScreen` (`lib/features/auth/screens/sign_in_screen.dart`) already has the Apple Sign In button, conditionally displayed for iOS/macOS/Web.

## Configuration Guide

The following steps are required to enable Apple Sign In for this project.

### Step 1: Apple Developer Setup
1.  Navigate to **Certificates, Identifiers & Profiles > Identifiers** on the Apple Developer Portal.
2.  Create a new **App ID** (or select the existing one).
3.  **Bundle ID**: `com.ras3ucat.bingeQuest`
4.  Enable **Sign in with Apple** in the capabilities list.
5.  Save the App ID.

### Step 2: Create a Services ID (for OAuth/Supabase)
This acts as your OAuth client ID for Supabase handling of the callback.
1.  Go to **Identifiers** and click **+**.
2.  Choose **Services IDs**.
3.  **Description**: `BingeQuest Supabase Login`
4.  **Identifier**: `com.ras3ucat.bingeQuest.login` (Example pattern)
5.  Click **Continue** and **Register**.
6.  Click your new Services ID to configure it.
7.  Enable **Sign in with Apple** and click **Configure**.
8.  **Primary App ID**: Select `com.ras3ucat.bingeQuest`.
9.  **Domains and Subdomains**: Add your Supabase project domain (without `https://`).
10. **Return URLs**: Add your Supabase callback URL:
    `https://<YOUR_PROJECT_ID>.supabase.co/auth/v1/callback`
11. Save and Continue.

### Step 3: Create a Private Key
1.  Go to **Keys** and click **+**.
2.  Name it (e.g., "Supabase Apple Sign In").
3.  Enable **Sign in with Apple**.
4.  Click **Configure** and select your App ID (`com.ras3ucat.bingeQuest`).
5.  Click **Save**, **Continue**, and **Register**.
6.  **Download** the `.p8` key file. **Store this safely**, you cannot download it again.
7.  Note the **Key ID** and your **Team ID**.

### Step 4: Configure Supabase
1.  Open your **Supabase Project Dashboard**.
2.  Go to **Authentication > Providers > Apple**.
3.  Toggle **Enable Apple**.
4.  Fill in the details:
    *   **Client ID**: `com.ras3ucat.bingeQuest.login` (The Services ID from Step 2)
    *   **Team ID**: Your Apple Team ID.
    *   **Key ID**: The Key ID from Step 3.
    *   **Private Key**: Paste the contents of the `.p8` file.
5.  Click **Save**.

### Step 5: Xcode Configuration (Completed)
This step has been handled manually by editing `project.pbxproj` and creating `Runner.entitlements`. No further action is required here unless build issues arise.
1.  **Entitlements**: `Runner.entitlements` created with `com.apple.developer.applesignin`.
2.  **Project File**: `project.pbxproj` updated to link the entitlements file.

## Proposed Code Changes
*   **None (Frontend)**: The Flutter code appears complete.
*   **None (Backend)**: No SQL changes required.

## Verification Plan

### Manual Verification
1.  **Simulator/Device Test**:
    - Run the app on an iOS Simulator or Real Device.
    - Navigate to the Sign In screen.
    - Tap "Continue with Apple".
    - Authenticate using the simulator's dummy account or real Apple ID.
    - Verify redirection to the Dashboard.
    - Verify user creation in Supabase "Users" table.

2.  **Account Deletion (Compliance)**:
    - Verify the "Delete Account" button functions correctly (already implemented in `AuthController`), as this is also an App Store requirement.
