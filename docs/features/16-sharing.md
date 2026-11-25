# 16 · Sharing

Written 2026-11-25 with the owner, after one round of design
(`design/review/sharing-designs.html`, published for review the same day).
The owner chose **V-C** for the ਅੱਜ ਦਾ ਵਿਚਾਰ card, **G-A** for the group
invite, **P-A** for a Sikh calendar day, and the four link previews (**L**).
The screens are numbered designs 132-137, drawn by
`tools/design/build_phase2.py`.

This file holds the ਅੱਜ ਦਾ ਵਿਚਾਰ card in full and the link previews. The
invite sheet's rules live in `08-sangat.md` (IV4, IV4a-IV4c) and the calendar
notification's in `02-notifications.md` (CE7, CE8), because those files own
the features; they are summarised here so sharing can be read in one place.

Why this exists: Hazri grows by being forwarded. Every Gurbani forward,
invite and Gurpurab message that goes into a family WhatsApp group can carry
the app with it, and a picture is opened where a line of text is scrolled
past. None of it rewards anybody for sharing (Play's policy on incentivised
installs, and PRD §1.3), and the app itself sends nothing: every share goes
through Android, to the app the person picks.

---

## 1. What it is not

- **Not a referral scheme.** No codes per person, no counts of who shared,
  no points, badges or prizes for sharing.
- **Not tracking.** Nothing records that a share happened. The links a card
  carries name the kind of card (`utm_campaign`), never the person.
- **Not an editor for Gurbani.** The line and its meaning are the day's row
  of `vichar` in `content.db`. Nothing on any card is typed into Dart, and the
  only free text a person can add is their own name (VC8).

---

## 2. The ਅੱਜ ਦਾ ਵਿਚਾਰ card (designs 132, 133, 134)

**VC1. Share opens Make a card.** Share on Today's Vichar card and on the
Vichar screen opens a full screen, **Make a card** (design 132), in place of
the sheet that asked "words or a picture". At the top, the card as it will be
sent; under it three tabs, **Style**, **Words** and **Size**; at the foot,
**WhatsApp** and **Share** (VC14). **As text** stays, top right: it sends
the words exactly as today's text share does (PRD §4.15).

**VC2. The line is never edited.** The card shows the day's line and its
meaning from `content.db`, chosen as today (days since 1970-01-01 modulo
200). No control changes, reflows by hand, shortens or translates them; the
type size fits the line to the card.

**VC3. Seven styles** (the Style tab, design 132), as a 3-column grid of
small previews of today's card:

| Style | Look | Note |
|---|---|---|
| **Of the day** (default) | Chosen for the day by VC4 | Its tile shows what it resolves to today |
| Folio | Today's card: warm paper, a double kesri rule, ੴ in the corner | Unchanged from PRD §4.15 |
| Amrit Vela | Night blue to saffron, a low sun | |
| Raat | Navy with a few stars, kesri accents | |
| Phulkari | A phulkari border of diamonds in magenta and gold round warm paper | |
| Bold | White, the line large and left-aligned, a short kesri bar | |
| Photo | `assets/vichar/dawn.jpg` under a dark wash | The owner's picture (2026-11-09); no other picture without its rights checked |

**VC4. Of the day.** On a date whose main event (VC5) is `shaheedi` or
`joti-jot`, Of the day is the **Remembrance** look: near-black to deep maroon,
a thin kesri frame. On `prakash` or `gurgaddi`, the **Prakash** look: warm
gold, a white frame. On any other day, **Amrit Vela**. Remembrance and
Prakash are reached only through Of the day, never on a day that is not
theirs.

**VC5. The day's main event** is the first of that date's
`calendar_event` rows, leaving out `supplementary` ones, in the order
`prakash`, `gurgaddi`, `shaheedi`, `joti-jot`, then any other kind, then by
`id`. A day with no row has no event.

**VC6. The date line** (on by default, switched in the Words tab): the
Nanakshahi date in the app language's script (੮ ਪੋਹ ੫੫੮ in Punjabi, with
Gurmukhi numerals; 8 Poh 558 in English and Hindi), and under it the main
event's name in a pill, by `02-notifications.md` CE4 (the English name where
the reader's is missing, never machine-translated). Puranmashi, Sangrand and
Masya appear here like any event; they do not change the style (VC4). This
line, with the day's line of Gurbani and VC4, is what makes the card
different every day without anybody choosing anything.

**VC7. Greetings** (the Words tab, design 133) are a fixed list that follows
the main event's kind. Nobody types a greeting.

| Day | Choices (first is the default) |
|---|---|
| No event, or an event of another kind | None; `vicharGreetMorning`; `vicharGreetFateh` |
| `shaheedi` | `vicharGreetShaheedi`; None; `vicharGreetFateh` |
| `joti-jot` | None; `vicharGreetFateh` |
| `prakash`, `gurgaddi` | `vicharGreetPurab`; None; `vicharGreetFateh` |

A remembrance day never offers a greeting that celebrates (the rule of
`02-notifications.md` CE3: never "Happy", never ਵਧਾਈਆਂ). The greeting
sits above the line and is the app language's text.

**VC8. From** (the Words tab): optional, up to 30 characters, shown at the
foot as `vicharFrom` ("From {name}"). It is the only free text on any card.
It is kept on the phone (`vichar_card_from`) and never sent; it is empty
until the person types it, and it is not filled from the profile.

**VC9. Meaning** (the Words tab): **ਪੰਜਾਬੀ**, **English**, **Both** or
**Line only**. The default follows the app language: Punjabi for `pa` and
`hi` (no reviewed Hindi meaning exists, PRD §4.15), English for `en`.

**VC10. Size** (the Size tab, design 134): **Status** 1080 × 1920 (the
default; what WhatsApp Status and Instagram stories take), **Post** 1080 ×
1350 (today's card), **Square** 1080 × 1080. Square leaves out the source
line "Sri Guru Granth Sahib Ji" only if the line would not otherwise fit;
it is never left out on the other two.

**VC11. The foot of every card:** Hazri's sun-arc mark, `shareCardFooter`
("Read daily on Hazri") and `hazri.me`. The Status size adds a QR code that
opens the Play listing with `utm_source=share&utm_campaign=vichar_card`
(VC15). `hazri.me` is printed, not linked; it already serves the website
(`docs/domain-setup.md`), and the app's own links stay on `kSiteBase`.

**VC12. What is remembered.** Style, size, meaning, the date line and From
are kept (ARCHITECTURE §3.8, `vichar_card_*`) and used the next time, so a
person who likes Raat in Square keeps getting it. The greeting is not kept:
it belongs to the day.

**VC13. The picture** is laid out at 360 points wide and rendered at 3×, in
its own palette, the same in either theme (as today's card). It is written
under a new name each time, as `writeShareImage` does, so Android's preview
is of the file being sent.

**VC14. Sending.** **WhatsApp** sends the picture and the caption
(`vicharShareCaption`) straight to WhatsApp (`com.whatsapp`, else
`com.whatsapp.w4b`). Where neither is installed the button is not shown and
**Share** fills the row. **Share** opens Android's share sheet with the same
picture and caption. Sending closes Make a card.

**VC15. The links.** Every card's caption and QR use one link,
`https://play.google.com/store/apps/details?id=app.hazri&referrer=utm_source%3Dshare%26utm_campaign%3D{campaign}`,
with `vichar_card` here and `event_card` for a calendar day (02 CE8).
Play Console's acquisition report reads it; the app reads nothing back and
records nothing. An invite keeps its own `/j/{code}` link (08 IV5, IV6),
because that link carries the code through the install.

**VC16. Elder mode** shows Make a card at elder sizes; nothing is hidden.

---

## 3. The group invite (design 135; rules in `08-sangat.md`)

Invite opens a sheet showing **the message exactly as it will be sent**, with
its language chosen by chips (ਪੰਜਾਬੀ, हिन्दी, English; the app language
first), then **Send on WhatsApp**, **Other apps** and **Copy code**. The
language can differ from the app's, because family abroad often reads
English. `08-sangat.md` IV4, IV4a-IV4c.

## 4. A Sikh calendar day (designs 136, 137; rules in `02-notifications.md`)

The evening-before and on-the-day notices carry **Share with family**. It
opens Hazri on the event's card, already made: one tap sends it.
`02-notifications.md` CE7, CE8.

---

## 5. Link previews (the website)

**LP1.** Four pictures, 1200 × 630, in `public/img/og/`, each named by an
`og:image` (with `og:image:width`, `og:image:height` and
`twitter:card` = `summary_large_image`) on its page:

| Page | Picture |
|---|---|
| `/j/` (every invite) | Navy, "Hazri sangat", **Join our paath. Every reading counts.**, a goal ring, Free · No ads · No login |
| `/q/` (every quiz) | Saffron to kesri, "Gurmat Quiz", **Can you beat my score? Five questions.**, Free in the Hazri app |
| `/` | Dawn, hazri.me, **Nitnem, Sukhmani Sahib and the Sikh calendar on your phone**, Free · No ads · Works offline |
| `/gurpurab/<slug>` | One per story: the Remembrance or Prakash look by the day's kind (VC4), otherwise navy; the kind and Nanakshahi date, the story's title, "Read the story on Hazri" |

**LP2.** Invite and quiz links share one picture each, because an invite is
made on the phone and the static site cannot draw it.

**LP3.** They are **built, not edited**: `tools/site/build.py` draws them
with the pages, from the same article data, so a new story gets its picture
when the site is rebuilt. No picture of a Guru, and no Gurbani, on any of
them.

**LP4.** They change nothing until `firebase deploy --only hosting:public`
(CLAUDE.md, "Neither is the website").

---

## 6. Strings

New keys, in every ARB. The Punjabi and Hindi are Claude's draft and want a
native ear before release.

| Key | English | ਪੰਜਾਬੀ | हिन्दी |
| --- | --- | --- | --- |
| `vicharCardTitle` | Make a card | ਕਾਰਡ ਬਣਾਓ | कार्ड बनाएँ |
| `vicharCardTabStyle` | Style | ਰੂਪ | रूप |
| `vicharCardTabWords` | Words | ਸ਼ਬਦ | शब्द |
| `vicharCardTabSize` | Size | ਆਕਾਰ | आकार |
| `vicharCardAsText` | As text | ਲਿਖਤ ਵਜੋਂ | टेक्स्ट में |
| `vicharCardWhatsApp` | WhatsApp | WhatsApp | WhatsApp |
| `vicharCardShare` | Share | ਸਾਂਝਾ ਕਰੋ | शेयर करें |
| `vicharStyleOfDay` | Of the day | ਅੱਜ ਦਾ | आज का |
| `vicharStyleFolio` | Folio | ਪੱਤਰਾ | पत्रा |
| `vicharStyleDawn` | Amrit Vela | ਅੰਮ੍ਰਿਤ ਵੇਲਾ | अमृत वेला |
| `vicharStyleNight` | Raat | ਰਾਤ | रात |
| `vicharStylePhulkari` | Phulkari | ਫੁਲਕਾਰੀ | फुलकारी |
| `vicharStyleBold` | Bold | ਗੂੜ੍ਹਾ | गाढ़ा |
| `vicharStylePhoto` | Photo | ਤਸਵੀਰ | तस्वीर |
| `vicharStyleResolves` | Today: {style} | ਅੱਜ: {style} | आज: {style} |
| `vicharStyleRemembrance` | Remembrance | ਯਾਦ | स्मरण |
| `vicharStylePrakash` | Prakash Purab | ਪ੍ਰਕਾਸ਼ ਪੁਰਬ | प्रकाश पर्व |
| `vicharWordsGreeting` | Greeting | ਸ਼ੁਭ ਇੱਛਾ | शुभकामना |
| `vicharWordsMeaning` | Meaning | ਅਰਥ | अर्थ |
| `vicharWordsFrom` | From | ਵੱਲੋਂ | की ओर से |
| `vicharWordsFromHint` | Your name, if you like. It stays on this phone. | ਚਾਹੋ ਤਾਂ ਆਪਣਾ ਨਾਮ। ਇਹ ਇਸ ਫ਼ੋਨ ’ਤੇ ਹੀ ਰਹਿੰਦਾ ਹੈ। | चाहें तो अपना नाम। यह इसी फ़ोन पर रहता है। |
| `vicharWordsDateLine` | Date and day | ਤਾਰੀਖ਼ ਅਤੇ ਦਿਹਾੜਾ | तारीख़ और दिन |
| `vicharMeaningBoth` | Both | ਦੋਵੇਂ | दोनों |
| `vicharMeaningNone` | Line only | ਸਿਰਫ਼ ਪੰਕਤੀ | सिर्फ़ पंक्ति |
| `vicharGreetNone` | None | ਕੋਈ ਨਹੀਂ | कोई नहीं |
| `vicharGreetMorning` | Good morning ji | ਸ਼ੁਭ ਸਵੇਰ ਜੀ | शुभ प्रभात जी |
| `vicharGreetFateh` | Waheguru Ji Ka Khalsa, Waheguru Ji Ki Fateh | ਵਾਹਿਗੁਰੂ ਜੀ ਕਾ ਖ਼ਾਲਸਾ, ਵਾਹਿਗੁਰੂ ਜੀ ਕੀ ਫ਼ਤਹਿ | वाहिगुरु जी का खालसा, वाहिगुरु जी की फ़तह |
| `vicharGreetShaheedi` | Our salute to the Shaheeds | ਸ਼ਹੀਦਾਂ ਨੂੰ ਕੋਟਿ ਕੋਟਿ ਪ੍ਰਣਾਮ | शहीदों को कोटि कोटि प्रणाम |
| `vicharGreetPurab` | Greetings on the Gurpurab | ਗੁਰਪੁਰਬ ਦੀਆਂ ਲੱਖ ਲੱਖ ਵਧਾਈਆਂ | गुरपुरब की लख लख बधाइयाँ |
| `vicharFrom` | From {name} | ਵੱਲੋਂ: {name} | {name} की ओर से |
| `vicharSizeStatus` | Status | ਸਟੇਟਸ | स्टेटस |
| `vicharSizePost` | Post | ਪੋਸਟ | पोस्ट |
| `vicharSizeSquare` | Square | ਵਰਗ | वर्गाकार |
| `vicharSizeStatusHint` | For WhatsApp Status and stories, with a QR code | WhatsApp ਸਟੇਟਸ ਅਤੇ ਸਟੋਰੀ ਲਈ, QR ਕੋਡ ਨਾਲ | WhatsApp स्टेटस और स्टोरी के लिए, QR कोड के साथ |
| `vicharSizePostHint` | For a chat or a feed | ਚੈਟ ਜਾਂ ਫ਼ੀਡ ਲਈ | चैट या फ़ीड के लिए |
| `vicharSizeSquareHint` | For a group's picture or a post | ਗਰੁੱਪ ਜਾਂ ਪੋਸਟ ਲਈ | ग्रुप या पोस्ट के लिए |
| `vicharShareCaption` | Today's Vichar. Read daily on Hazri: {link} | ਅੱਜ ਦਾ ਵਿਚਾਰ। ਹਰ ਰੋਜ਼ ਹਾਜ਼ਰੀ ’ਤੇ ਪੜ੍ਹੋ: {link} | आज का विचार। हर रोज़ हाज़री पर पढ़ें: {link} |

`vicharGreetShaheedi` is said on a Shaheedi day only; `vicharGreetPurab` on a
Prakash or Gurgaddi day only (VC7). The invite's and the calendar's strings
are in their own files.

---

## 7. Scenarios

- **An ordinary day.** Given 2 Dec 2026 (17 Maghar 558, no event) and no
  choices kept, when Share is tapped on Today's Vichar card, then Make a card
  opens on Of the day showing Amrit Vela, Status size, the Punjabi meaning (app
  language `pa`), no greeting, and the date line "੧੭ ਮੱਘਰ ੫੫੮" with no pill.
- **A Shaheedi day.** Given 23 Dec 2026, when Make a card opens on Of the
  day, then the card is the Remembrance look, the greeting is
  ਸ਼ਹੀਦਾਂ ਨੂੰ ਕੋਟਿ ਕੋਟਿ ਪ੍ਰਣਾਮ, the pill names the `shaheedi` event (before
  Saka Chamkaur Sahib's `historical` row and Puranmashi, by VC5), and
  `vicharGreetPurab` is not among the choices.
- **A kept style.** Given a person who last sent Raat in Square, when Make
  a card opens on 15 Jan 2027 (Prakash Purab), then it opens on Raat in
  Square, with the date line and the default greeting of the day.
- **From.** Given "Harpreet and family" typed in From, when the card is sent
  and Make a card is opened next week, then From still reads "Harpreet and
  family"; and no request the app makes carries it (a test greps
  `lib/core/backend/` and `lib/features/*/data/` for `vichar_card_from`).
- **No WhatsApp.** Given a phone with neither WhatsApp package, then the
  WhatsApp button is not shown and Share fills the row.
- **Failure: the line does not fit.** Given the longest of the 200 lines,
  Both meanings, a greeting and the Square size, then the type shrinks to fit
  and nothing is cut; a test renders every line at every size with both
  meanings and checks nothing overflows.
- **Failure: no calendar data.** Given a date after 13 Mar 2027 before
  Nanakshahi 559 is added, then there is no date line and no event, Of the
  day is Amrit Vela, and nothing throws.

---

## 8. Acceptance

- [ ] Designs 132-134 match the built screen; 135 the invite sheet; 136 and
      137 the notification and the event card.
- [ ] Every scenario in §7 is a test.
- [ ] No Gurbani string is added to Dart or an ARB file.
- [ ] `vichar_card_*` keys are in ARCHITECTURE §3.8 and nowhere else.
- [ ] The four preview pictures are built by `tools/site/build.py`, and
      hosting is deployed.
- [ ] The Punjabi and Hindi strings of §6 have had a native read.
