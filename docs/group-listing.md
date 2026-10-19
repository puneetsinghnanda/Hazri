> **History (2026-10-19).** This procedure belongs to the first Sangat, which
> was removed in PRD §11 step 6. Groups are now built-in (made in the admin
> website, `docs/features/11-admin.md`) or private by invite; there is no
> listing to approve. Kept for the record only.

# Approving a group for the Sangat list

A group made in the app is **always private**. It works immediately — the
maker can invite people with the link and the shared goal counts from the
first paath — but it does not appear under "Groups you can join" until
somebody has read its name.

That is deliberate, and it is the answer to the question this feature always
raises: what stops a hurtful or misleading name being shown to people who
never met whoever chose it. The app cannot answer that, so it does not try.

## Why a phone cannot do it

`firestore.rules` refuses `listed` on create and pins it on update, so
**there is no sequence of taps that lists a group**, including by its own
admin. It is not a UI convention that could be worked around; the server
refuses the write.

## What the app records

When somebody picks "Listed in Sangat" on the create screen, the group is
still created private and one extra field is written:

```
groups/{groupId}
  name:              "Nanda Family"
  kind:              "family" | "sangat" | "circle"
  createdBy:         "<uid>"
  listed:            false      ← only we can change this
  listingRequested:  true       ← the maker asked
```

The create screen says what happens and roughly how long it takes, before
the group is made, so nobody is waiting on something they were not told about.

## Approving one

In the Firebase console, Firestore Database → `groups`:

1. Filter or sort by `listingRequested == true`.
2. Read the name. Reject anything that misrepresents a gurdwara or an
   organisation it does not speak for, anything abusive, and anything that
   would read as official when it is not.
3. To approve: set `listed` to `true`.
4. To decline: set `listingRequested` to `false` and leave `listed` false.
   The group carries on working privately, which is what it was doing anyway.

There is no admin screen for this in Phase 2 and no notification to the
maker either way. Both are worth building when there are enough groups for
the console to become tedious; until then a console edit is the whole of it,
and an approval takes about ten seconds.

## What a listed group changes

Only discovery. A listed group appears in "Groups you can join" for anybody
signed in, and can then be joined without a link. Its members, its goal and
its counts behave exactly as a private group's do.
