// Sayings constants for Watch Party progress rows.
// All lists are const. {name} is replaced at render time via resolveSaying().

// ---------------------------------------------------------------------------
// First Place (10 sayings, third-person with {name})
// ---------------------------------------------------------------------------
const List<String> kFirstPlaceSayings = [
  'No spoilers, {name}.',
  'Slow down, {name}.',
  'We see you, {name}.',
  'Pause and wait for us, {name}.',
  '{name} is not here to pace themselves.',
  '{name} came here to win.',
  'At this rate, {name} will finish before we hit episode three.',
  'Too fast, {name}.',
  '{name} is a force of nature.',
  '{name} clearly blocked off the whole weekend.',
];

// ---------------------------------------------------------------------------
// First Place — Self (10 sayings, second-person, no {name})
// ---------------------------------------------------------------------------
const List<String> kFirstPlaceSelfSayings = [
  'You are ahead. No spoilers.',
  'Slow down. Wait for them.',
  'They see you.',
  'Pause. Let them catch up.',
  'You are not here to pace yourself, are you.',
  'You came here to win.',
  'At this rate you will finish alone.',
  'Too fast. Even for you.',
  'You are a force of nature apparently.',
  'You blocked off the whole weekend for this.',
];

// ---------------------------------------------------------------------------
// Last Place (10 sayings, third-person with {name})
// ---------------------------------------------------------------------------
const List<String> kLastPlaceSayings = [
  'Did {name} fall asleep?',
  'Someone check on {name}.',
  '{name} is still on episode one.',
  'Is {name} even watching?',
  'No pressure, {name}. But hurry up.',
  '{name} really committed to taking it slow.',
  'No rush, {name}. Really. No rush.',
  '{name} needs to catch up.',
  '{name} takes their time.',
  '{name} is officially the weak link.',
];

// ---------------------------------------------------------------------------
// Last Place — Self (10 sayings, second-person, no {name})
// ---------------------------------------------------------------------------
const List<String> kLastPlaceSelfSayings = [
  'Did you fall asleep?',
  'We are checking on you.',
  'You are still on episode one.',
  'Are you even watching?',
  'No pressure. But maybe some pressure.',
  'You really committed to taking it slow.',
  'No rush. Really. No rush.',
  'You need to catch up.',
  'Taking your time, as usual.',
  'You are officially the weak link.',
];

// ---------------------------------------------------------------------------
// Middle Place (20 sayings, with {name})
// ---------------------------------------------------------------------------
const List<String> kMiddleSayings = [
  'Not first, not last. Classic {name}.',
  '{name} is right where they want to be.',
  'Comfortably in the middle, as is tradition for {name}.',
  '{name} is playing it safe.',
  'Dependable as ever, {name}.',
  '{name} refuses to commit to a side.',
  'Solidly mid. Respect, {name}.',
  'Neither fast nor slow. {name} found the sweet spot.',
  '{name} has seen enough to contribute to the conversation.',
  '{name} watched just enough to have opinions.',
  'Classic middle-child energy from {name}.',
  'Not winning, not losing. {name} is vibing.',
  '{name} is unbothered and perfectly on pace.',
  'Somewhere in the middle, {name} found peace.',
  '{name} is taking the scenic route.',
  'Right in the thick of it: {name}.',
  '{name} has a measured approach to all things.',
  '{name} is exactly where expected.',
  'Balanced, neutral, {name}.',
  '{name} is the true median of this group.',
];

// ---------------------------------------------------------------------------
// Not Started (6 sayings, with {name})
// ---------------------------------------------------------------------------
const List<String> kNotStartedSayings = [
  '{name} hasn\'t even pressed play yet.',
  'Still waiting on {name}.',
  '{name} has not started. Bold strategy.',
  'Whenever you\'re ready, {name}.',
  '{name} is saving it for a special occasion apparently.',
  'The journey has not yet begun for {name}.',
];

// ---------------------------------------------------------------------------
// Completed (6 sayings, with {name})
// ---------------------------------------------------------------------------
const List<String> kCompletedSayings = [
  '{name} has seen everything. Tread carefully.',
  '{name} is waiting for the rest of you.',
  '{name} finished. No further questions.',
  '{name} is ready for the next binge.',
  '{name} knows how it ends.',
  '{name} has reached the other side.',
];

// ---------------------------------------------------------------------------
// Tied (10 sayings, with {name})
// ---------------------------------------------------------------------------
const List<String> kTiedSayings = [
  '{name} is locked in step.',
  'Exactly on pace: {name}.',
  'Right there with the pack, {name}.',
  '{name} refuses to pull ahead.',
  'Neck and neck. Eyes forward, {name}.',
  '{name} is keeping it close.',
  'Nobody blinked yet. Not even {name}.',
  '{name} is holding steady.',
  'Matched. {name} knows what they are doing.',
  '{name} is right in the mix.',
];

// ---------------------------------------------------------------------------
// Nudge Sayings (10, no {name}, randomized fresh per nudge tap)
// ---------------------------------------------------------------------------
const List<String> kNudgeSayings = [
  'The group is waiting on you.',
  'Time to press play.',
  'They need you to catch up.',
  'The watch party misses you.',
  'Consider this your formal notice to catch up.',
  'Someone from the group wants you to hurry up.',
  'You have been nudged.',
  'The group sent a search party.',
  'Your presence has been requested.',
  'Catch up. Please.',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Replaces all occurrences of `{name}` in [template] with [name].
String resolveSaying(String template, String name) =>
    template.replaceAll('{name}', name);

/// True when member at [index] has the same score as an adjacent neighbour.
bool isTiedAt(int index, List<int> scores) {
  final score = scores[index];
  if (score < 0) return false;
  final prevTied = index > 0 && scores[index - 1] == score;
  final nextTied = index < scores.length - 1 && scores[index + 1] == score;
  return prevTied || nextTied;
}

/// Returns the saying string for member at [index], or null when none applies.
/// Priority: notStarted > completed > tied > first > middle > last.
/// notStarted and completed sayings show regardless of party size.
/// Position sayings (first/last/middle/tied) require total >= 2.
String? sayingFor({
  required int index,
  required int total,
  required String displayName,
  required bool episodesEmpty,
  required bool isAllWatched,
  required bool isTied,
  required bool isSelf,
  required int firstPlaceIdx,
  required int lastPlaceIdx,
  required int middleIdx,
  required int notStartedIdx,
  required int completedIdx,
  required int tiedIdx,
}) {
  if (episodesEmpty) {
    return resolveSaying(
      kNotStartedSayings[notStartedIdx % kNotStartedSayings.length],
      displayName,
    );
  }
  if (isAllWatched) {
    return resolveSaying(
      kCompletedSayings[completedIdx % kCompletedSayings.length],
      displayName,
    );
  }
  // Position sayings only make sense with 2+ members.
  if (total < 2) return null;
  if (isTied) {
    return resolveSaying(
      kTiedSayings[tiedIdx % kTiedSayings.length],
      displayName,
    );
  }
  if (index == 0) {
    if (isSelf) return kFirstPlaceSelfSayings[firstPlaceIdx];
    return resolveSaying(kFirstPlaceSayings[firstPlaceIdx], displayName);
  }
  if (index == total - 1) {
    if (isSelf) return kLastPlaceSelfSayings[lastPlaceIdx];
    return resolveSaying(kLastPlaceSayings[lastPlaceIdx], displayName);
  }
  if (total >= 3 && index == total ~/ 2) {
    return resolveSaying(
      kMiddleSayings[middleIdx % kMiddleSayings.length],
      displayName,
    );
  }
  return null;
}
