# Feature: Friend System

## Status
TODO

## Overview
Allow users to connect with friends, see what they are watching, and compare progress.

## Acceptance Criteria
- [ ] Send/Accept/Decline friend requests
- [ ] Friend list on profile
- [ ] "Friend is also watching" indicator on content pages

## Backend Changes
- `friendships` table (pending, accepted, blocked)
- RLS policies for friend-only data visibility

## Frontend Changes
- `FriendRepository` and `FriendController`
- UI: Friend search and management screens
- UI: Social indicators on item detail pages

## QA Checklist
- [ ] Verify friend requests are received
- [ ] Verify privacy (only friends can see certain stats)
