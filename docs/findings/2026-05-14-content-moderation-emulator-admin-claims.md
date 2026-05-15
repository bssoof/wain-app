# Content moderation emulator admin-claims setup issue

Date: 2026-05-14

## Summary

The story analytics work exposed an unrelated emulator-only failure in
`contentModerationCallableFlows`: nine tests fail with `Requires admin privileges`.

## Scope

This is outside the Story Analytics + Funnel feature. The targeted story
analytics emulator tests pass, and the failure appears tied to test seed/admin
claim setup for content moderation callables.

## Current Evidence

- Failing suite: `functions/test/emulator/contentModerationCallableFlows.test.js`
- Failure class: permission/admin privilege rejection
- Observed while running the broader emulator suite after the story analytics
  backend changes.

## Follow-up

Investigate the content moderation emulator seed and admin claim setup before
enabling strict full-emulator CI for this branch. Do not treat this as a blocker
for the story analytics data pipeline unless the same admin setup is reused by
story analytics callables.
