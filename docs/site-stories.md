# The story pages at hazri.me/gurpurab

One page for every day of the Nanakshahi 558 calendar: 102 pages covering all
147 days in `tools/site/cal.json`. One page serves the twelve Sangrands, one
the twelve Masyas, one the eleven Puranmashis, and a few pages serve two or
three days that tell the same story (a Saka and its shaheeds, a birth
anniversary and a Shaheedi Purab, the two days of a Jorh Mela).

**How they are made.** The text is in `tools/site/articles/*.json`;
`tools/site/articles.py`, called by `python3 tools/site/build.py`, writes
`public/gurpurab/<slug>.html`, the index `public/gurpurab/index.html`,
`public/stories.css`, `public/sitemap.xml` and `public/robots.txt`. The build
fails if a calendar day has no page, if an article names a day the calendar
does not have, or if a page is under 200 words. The home page's calendar card
now shows each day's whole story and links "Read the full story" to its page.

**Topics.** Every page carries one or more of four topics, Gurudwaras, Guru Sahibans, Banis and Sikh Days, set in
`tools/site/categories.json` (a list of page slugs per topic). They show as links under each title and on the
index, and each has its own page at `/gurpurab/topic/<topic>`. The build fails if a page has no topic.

**What the pages are not.** None of them quotes Gurbani, and no picture is of
a Guru (CLAUDE.md rule 3): the photographs are of places. The history is
written from widely accepted accounts and the calendar's own stories; where
traditions differ, the page says so. **Every page wants a reader who knows
the history before it goes live**, the twentieth-century ones above all
(June 1984, Sant Jarnail Singh Ji, Bhai Beant Singh, Sant Longowal), which
are written to state what happened and that views differ, nothing more.

**Photographs: still to review.** Each `img` is a Wikimedia Commons file,
shown from Commons (`Special:FilePath`, 1280 px) with a caption and a link to
its file page, where the author and licence are recorded. Wikimedia was not
reachable from the machine that wrote these, so each file was found through a
search index and **none has been looked at**. Check that each shows what its
caption says, that its licence allows reuse (most are CC BY-SA, which also
wants the author named, so the credit may need the author's name rather than
only the link), and that none is a painting of a Guru. If a photo fails to
load, the page draws its own illustration in its place; 34 pages have no photo
and always show the illustration. Loading a photo from Commons means a
reader's browser asks Wikimedia for it, as it already asks Google for the
fonts; copying approved photos into `public/img/` would end that.

**Google Play.** The "Get it on Google Play" poster after every story links to
`https://play.google.com/store/apps/details?id=app.hazri`, which answers
404 until the listing is published. The home page still says "Coming soon".

**Going live.** Nothing changes on hazri.me until somebody runs
`firebase deploy --only hosting:public`. After that, submit
`https://hazri.me/sitemap.xml` in Google Search Console.

| Page | Photograph |
|---|---|
| [prakash-purab-guru-nanak-dev-ji](https://hazri.me/gurpurab/prakash-purab-guru-nanak-dev-ji) | [Gurdwara_Nankana_Sahib_Janam_Asthan.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Nankana_Sahib_Janam_Asthan.jpg) |
| [prakash-purab-guru-angad-dev-ji](https://hazri.me/gurpurab/prakash-purab-guru-angad-dev-ji) | [Photograph_of_Gurdwara_Sri_Darbar_Sahib_in_Khadur_Sahib,_as_published_in_the_Mahan_Kosh_(1930).jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_Gurdwara_Sri_Darbar_Sahib_in_Khadur_Sahib,_as_published_in_the_Mahan_Kosh_(1930).jpg) |
| [prakash-purab-guru-amar-das-ji](https://hazri.me/gurpurab/prakash-purab-guru-amar-das-ji) | [Gurdwara_Janam_Asthan_Guru_Amar_Das.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Janam_Asthan_Guru_Amar_Das.jpg) |
| [prakash-purab-guru-ram-das-ji](https://hazri.me/gurpurab/prakash-purab-guru-ram-das-ji) | [Amrit_Sarovar,_Harmandir_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Amrit_Sarovar,_Harmandir_Sahib.jpg) |
| [prakash-purab-guru-arjan-dev-ji](https://hazri.me/gurpurab/prakash-purab-guru-arjan-dev-ji) | [Gurdwara_Bibi_Bhani.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Bibi_Bhani.jpg) |
| [prakash-purab-guru-hargobind-sahib-ji](https://hazri.me/gurpurab/prakash-purab-guru-hargobind-sahib-ji) | — (drawn illustration) |
| [prakash-purab-guru-harkrishan-sahib-ji](https://hazri.me/gurpurab/prakash-purab-guru-harkrishan-sahib-ji) | [The_Sarovar_at_Gurudwara_Bangla_Sahib,_Delhi.jpg](https://commons.wikimedia.org/wiki/File:The_Sarovar_at_Gurudwara_Bangla_Sahib,_Delhi.jpg) |
| [prakash-purab-guru-tegh-bahadur-ji](https://hazri.me/gurpurab/prakash-purab-guru-tegh-bahadur-ji) | — (drawn illustration) |
| [prakash-purab-guru-gobind-singh-ji](https://hazri.me/gurpurab/prakash-purab-guru-gobind-singh-ji) | [Takht_Sri_Patna_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Takht_Sri_Patna_Sahib.jpg) |
| [pehla-prakash-purab-guru-granth-sahib-ji](https://hazri.me/gurpurab/pehla-prakash-purab-guru-granth-sahib-ji) | [Harmandir_Sahib,_Amritsar,_India.jpg](https://commons.wikimedia.org/wiki/File:Harmandir_Sahib,_Amritsar,_India.jpg) |
| [gurgaddi-purab-guru-angad-dev-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-angad-dev-ji) | [Gurdwara_Darbar_Sahib_Kartarpur_g.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Darbar_Sahib_Kartarpur_g.jpg) |
| [gurgaddi-purab-guru-amar-das-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-amar-das-ji) | [Historical_photograph_of_Gurdwara_Sri_Khadur_Sahib,_ca.1920's._Published_in_the_1930_first_edition_of_Mahan_Kosh_by_Kahn_Singh_Nabha.jpg](https://commons.wikimedia.org/wiki/File:Historical_photograph_of_Gurdwara_Sri_Khadur_Sahib,_ca.1920's._Published_in_the_1930_first_edition_of_Mahan_Kosh_by_Kahn_Singh_Nabha.jpg) |
| [gurgaddi-purab-guru-ram-das-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-ram-das-ji) | [Gurudwara_Goindwal_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_Goindwal_Sahib.jpg) |
| [gurgaddi-purab-guru-arjan-dev-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-arjan-dev-ji) | [Golden_Temple_Amritsar_Sarovar.JPG](https://commons.wikimedia.org/wiki/File:Golden_Temple_Amritsar_Sarovar.JPG) |
| [gurgaddi-purab-guru-hargobind-sahib-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-hargobind-sahib-ji) | [Akal_Takht_and_Harmandir_Sahib,_Amritsar,_Punjab,_India.jpg](https://commons.wikimedia.org/wiki/File:Akal_Takht_and_Harmandir_Sahib,_Amritsar,_Punjab,_India.jpg) |
| [gurgaddi-purab-guru-har-rai-sahib-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-har-rai-sahib-ji) | [Kiratpur_Gurudwara.jpg](https://commons.wikimedia.org/wiki/File:Kiratpur_Gurudwara.jpg) |
| [gurgaddi-purab-guru-harkrishan-sahib-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-harkrishan-sahib-ji) | [Gurdwara_Patalpuri,_in_Kiratpur,_Punjab,_India.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Patalpuri,_in_Kiratpur,_Punjab,_India.jpg) |
| [gurgaddi-purab-guru-tegh-bahadur-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-tegh-bahadur-ji) | [Baba_Bakala_Darbar_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Baba_Bakala_Darbar_Sahib.jpg) |
| [gurgaddi-purab-guru-gobind-singh-ji](https://hazri.me/gurpurab/gurgaddi-purab-guru-gobind-singh-ji) | [Photograph_of_Takht_Kesgarh_Sahib,_Anandpur_Sahib,_Punjab,_India,_ca.1952_01.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_Takht_Kesgarh_Sahib,_Anandpur_Sahib,_Punjab,_India,_ca.1952_01.jpg) |
| [gurta-gaddi-diwas-guru-granth-sahib-ji](https://hazri.me/gurpurab/gurta-gaddi-diwas-guru-granth-sahib-ji) | [Takht_Shri_Hazoor_Sahib_Gurudwara_Nanded.JPG](https://commons.wikimedia.org/wiki/File:Takht_Shri_Hazoor_Sahib_Gurudwara_Nanded.JPG) |
| [guru-khalsa-panj-pyare-chamkaur-sahib](https://hazri.me/gurpurab/guru-khalsa-panj-pyare-chamkaur-sahib) | [Gurudwara_shri_garhi_sahib_Chamkaur_sahib_-_panoramio.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_shri_garhi_sahib_Chamkaur_sahib_-_panoramio.jpg) |
| [joti-jot-purab-guru-nanak-dev-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-nanak-dev-ji) | [Gurdwara_Darbar_Sahib_Kartarpur_,Pakistan_03.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Darbar_Sahib_Kartarpur_,Pakistan_03.jpg) |
| [joti-jot-purab-guru-angad-dev-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-angad-dev-ji) | [Photograph_of_a_Sikh_congregation_at_the_Katha_Asthan_in_Tarn_Taran,_circa_late_19th_or_early_20th_century.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_a_Sikh_congregation_at_the_Katha_Asthan_in_Tarn_Taran,_circa_late_19th_or_early_20th_century.jpg) |
| [joti-jot-purab-guru-amar-das-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-amar-das-ji) | [Gurdwara_Baoli_Sahib,_Goindwal_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Baoli_Sahib,_Goindwal_Sahib.jpg) |
| [joti-jot-purab-guru-ram-das-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-ram-das-ji) | [Photograph_of_Gurdwara_Baoli_Sahib,_Goindwal,_circa_late_19th_or_early_20th_century.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_Gurdwara_Baoli_Sahib,_Goindwal,_circa_late_19th_or_early_20th_century.jpg) |
| [joti-jot-purab-guru-hargobind-sahib-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-hargobind-sahib-ji) | [Gurdwara_Patalpuri_Sahib_Kiratpur_India.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Patalpuri_Sahib_Kiratpur_India.jpg) |
| [joti-jot-purab-guru-har-rai-sahib-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-har-rai-sahib-ji) | [Gurdwara_Charan_Kamal,_Kiratpur_Sahib,_Punjab.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Charan_Kamal,_Kiratpur_Sahib,_Punjab.jpg) |
| [joti-jot-purab-guru-harkrishan-sahib-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-harkrishan-sahib-ji) | [Front_view_of_Gurudwara_Bangla_Sahib,_Delhi.jpg](https://commons.wikimedia.org/wiki/File:Front_view_of_Gurudwara_Bangla_Sahib,_Delhi.jpg) |
| [joti-jot-purab-guru-gobind-singh-ji](https://hazri.me/gurpurab/joti-jot-purab-guru-gobind-singh-ji) | [Hazur_Sahib,_Nanded,_Maharashtra,_September_2012.jpg](https://commons.wikimedia.org/wiki/File:Hazur_Sahib,_Nanded,_Maharashtra,_September_2012.jpg) |
| [bhai-mardana-ji-akal-chalana](https://hazri.me/gurpurab/bhai-mardana-ji-akal-chalana) | — (drawn illustration) |
| [shaheedi-purab-guru-arjan-dev-ji](https://hazri.me/gurpurab/shaheedi-purab-guru-arjan-dev-ji) | [Gurdwara_Dera_Sahib_Lahore.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Dera_Sahib_Lahore.jpg) |
| [shaheedi-purab-guru-tegh-bahadur-ji](https://hazri.me/gurpurab/shaheedi-purab-guru-tegh-bahadur-ji) | [Gurudwara_Sis_Ganj_Sahib_in_Old_Delhi_03.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_Sis_Ganj_Sahib_in_Old_Delhi_03.jpg) |
| [shaheedi-bhai-mati-das-sati-das-dyala-ji](https://hazri.me/gurpurab/shaheedi-bhai-mati-das-sati-das-dyala-ji) | [Gurudwara_Sis_Ganj_Sahib_in_Old_Delhi_02.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_Sis_Ganj_Sahib_in_Old_Delhi_02.jpg) |
| [shaheedi-bhai-jaita-ji-bhai-jivan-singh](https://hazri.me/gurpurab/shaheedi-bhai-jaita-ji-bhai-jivan-singh) | [Gurudwara_Sisganj_Sahib.JPG](https://commons.wikimedia.org/wiki/File:Gurudwara_Sisganj_Sahib.JPG) |
| [saka-chamkaur-sahib](https://hazri.me/gurpurab/saka-chamkaur-sahib) | [Gurdwara_Sri_Katalgarh_Sahib.JPG](https://commons.wikimedia.org/wiki/File:Gurdwara_Sri_Katalgarh_Sahib.JPG) |
| [shaheedi-bhai-sangat-singh-ji](https://hazri.me/gurpurab/shaheedi-bhai-sangat-singh-ji) | [Chamkaur_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Chamkaur_Sahib.jpg) |
| [saka-sirhind-chhote-sahibzade-mata-gujri-ji](https://hazri.me/gurpurab/saka-sirhind-chhote-sahibzade-mata-gujri-ji) | [Gurdwara_Fatehgarh_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Fatehgarh_Sahib.jpg) |
| [shaheedi-baba-banda-singh-bahadur](https://hazri.me/gurpurab/shaheedi-baba-banda-singh-bahadur) | — (drawn illustration) |
| [shaheedi-purab-bhai-mani-singh-ji](https://hazri.me/gurpurab/shaheedi-purab-bhai-mani-singh-ji) | — (drawn illustration) |
| [bhai-taru-singh-ji](https://hazri.me/gurpurab/bhai-taru-singh-ji) | — (drawn illustration) |
| [baba-deep-singh-ji](https://hazri.me/gurpurab/baba-deep-singh-ji) | [Photograph_of_Gurdwara_Shaheed_Baba_Deep_Singh_Ji,_Amritsar,_by_Jasleen_Kaur,_11_December_2008.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_Gurdwara_Shaheed_Baba_Deep_Singh_Ji,_Amritsar,_by_Jasleen_Kaur,_11_December_2008.jpg) |
| [shaheedi-baba-gurbakhsh-singh-ji](https://hazri.me/gurpurab/shaheedi-baba-gurbakhsh-singh-ji) | [Gurdwara_baba_Gurbax_singh_shahid.JPG](https://commons.wikimedia.org/wiki/File:Gurdwara_baba_Gurbax_singh_shahid.JPG) |
| [wadda-ghallughara-kup-rohira](https://hazri.me/gurpurab/wadda-ghallughara-kup-rohira) | — (drawn illustration) |
| [shaheedi-bhai-subeg-singh-bhai-shahbaz-singh](https://hazri.me/gurpurab/shaheedi-bhai-subeg-singh-bhai-shahbaz-singh) | — (drawn illustration) |
| [saka-nankana-sahib-1921](https://hazri.me/gurpurab/saka-nankana-sahib-1921) | [The_Gurdwara_Janam_Asthan_in_Nankana_Sahib,_Pakistan._05.jpg](https://commons.wikimedia.org/wiki/File:The_Gurdwara_Janam_Asthan_in_Nankana_Sahib,_Pakistan._05.jpg) |
| [shaheedi-kartar-singh-sarabha](https://hazri.me/gurpurab/shaheedi-kartar-singh-sarabha) | — (drawn illustration) |
| [shaheedi-udham-singh](https://hazri.me/gurpurab/shaheedi-udham-singh) | [Jallianwala_Bagh_Memorial_in_Amritsar.jpg](https://commons.wikimedia.org/wiki/File:Jallianwala_Bagh_Memorial_in_Amritsar.jpg) |
| [shaheedi-bhagat-singh](https://hazri.me/gurpurab/shaheedi-bhagat-singh) | — (drawn illustration) |
| [shaheedi-saka-paonta-sahib](https://hazri.me/gurpurab/shaheedi-saka-paonta-sahib) | [GURUDWARA_SRI_PAONTA_SAHIB.jpg](https://commons.wikimedia.org/wiki/File:GURUDWARA_SRI_PAONTA_SAHIB.jpg) |
| [ghallughara-1984-akal-takht-sahib](https://hazri.me/gurpurab/ghallughara-1984-akal-takht-sahib) | [GURUDWARA_SRI_AKAL_TAKHT_SAHIB.jpg](https://commons.wikimedia.org/wiki/File:GURUDWARA_SRI_AKAL_TAKHT_SAHIB.jpg) |
| [sant-jarnail-singh-ji-khalsa-bhindranwale](https://hazri.me/gurpurab/sant-jarnail-singh-ji-khalsa-bhindranwale) | — (drawn illustration) |
| [shaheedi-sant-harchand-singh-longowal](https://hazri.me/gurpurab/shaheedi-sant-harchand-singh-longowal) | — (drawn illustration) |
| [shaheedi-bhai-beant-singh](https://hazri.me/gurpurab/shaheedi-bhai-beant-singh) | — (drawn illustration) |
| [sahibzada-baba-ajit-singh-ji](https://hazri.me/gurpurab/sahibzada-baba-ajit-singh-ji) | [Gurudwara_shri_Chamkaur_sahib_-_panoramio.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_shri_Chamkaur_sahib_-_panoramio.jpg) |
| [sahibzada-baba-jujhar-singh-ji](https://hazri.me/gurpurab/sahibzada-baba-jujhar-singh-ji) | [Gurudwara_shri_damdama_sahib,_chamkaur_sahib_-_panoramio.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_shri_damdama_sahib,_chamkaur_sahib_-_panoramio.jpg) |
| [sahibzada-baba-zorawar-singh-ji](https://hazri.me/gurpurab/sahibzada-baba-zorawar-singh-ji) | [Fatehgarh_Sahib_as_seen_from_(thanda_buhrj).jpg](https://commons.wikimedia.org/wiki/File:Fatehgarh_Sahib_as_seen_from_(thanda_buhrj).jpg) |
| [sahibzada-baba-fateh-singh-ji](https://hazri.me/gurpurab/sahibzada-baba-fateh-singh-ji) | [Sarovar_(sacred_pool)_at_Fatehgarh_Sahib_Gurdwara,_Punjab,_India.jpg](https://commons.wikimedia.org/wiki/File:Sarovar_(sacred_pool)_at_Fatehgarh_Sahib_Gurdwara,_Punjab,_India.jpg) |
| [bhai-daya-singh-ji](https://hazri.me/gurpurab/bhai-daya-singh-ji) | [GURUDWARA_SHRI_KESGARH_SAHIB,_ANAND_PUR_SAHIB,_PUNJAB.jpg](https://commons.wikimedia.org/wiki/File:GURUDWARA_SHRI_KESGARH_SAHIB,_ANAND_PUR_SAHIB,_PUNJAB.jpg) |
| [bhai-dharam-singh-ji](https://hazri.me/gurpurab/bhai-dharam-singh-ji) | [Anandpur_Sahib_(1)_02.jpg](https://commons.wikimedia.org/wiki/File:Anandpur_Sahib_(1)_02.jpg) |
| [bhai-himmat-singh-ji](https://hazri.me/gurpurab/bhai-himmat-singh-ji) | [Photograph_of_Takht_Kesgarh_Sahib,_Anandpur_Sahib,_Punjab,_India,_ca.1952_04.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_Takht_Kesgarh_Sahib,_Anandpur_Sahib,_Punjab,_India,_ca.1952_04.jpg) |
| [bhai-mohkam-singh-ji](https://hazri.me/gurpurab/bhai-mohkam-singh-ji) | [Entrance_to_Gate_to_Takht_Sri_Kesgarh_Sahib_at_Night,_with_clock_visible_on_top.jpg](https://commons.wikimedia.org/wiki/File:Entrance_to_Gate_to_Takht_Sri_Kesgarh_Sahib_at_Night,_with_clock_visible_on_top.jpg) |
| [bhai-sahib-singh-ji](https://hazri.me/gurpurab/bhai-sahib-singh-ji) | [East_view_of_Anandpur_Sahib_city_Punjab_India.jpg](https://commons.wikimedia.org/wiki/File:East_view_of_Anandpur_Sahib_city_Punjab_India.jpg) |
| [mata-sahib-kaur-ji](https://hazri.me/gurpurab/mata-sahib-kaur-ji) | — (drawn illustration) |
| [baba-budha-ji](https://hazri.me/gurpurab/baba-budha-ji) | [Gurdwara_Baba_Budha_Sahib,_near_Amritsar.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Baba_Budha_Sahib,_near_Amritsar.jpg) |
| [bhagat-dhanna-ji](https://hazri.me/gurpurab/bhagat-dhanna-ji) | — (drawn illustration) |
| [bhagat-kabir-ji](https://hazri.me/gurpurab/bhagat-kabir-ji) | — (drawn illustration) |
| [bhagat-namdev-ji](https://hazri.me/gurpurab/bhagat-namdev-ji) | [Gurudwara_Bhagat_Namdev_Ji.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_Bhagat_Namdev_Ji.jpg) |
| [bhagat-ravidas-ji](https://hazri.me/gurpurab/bhagat-ravidas-ji) | — (drawn illustration) |
| [jassa-singh-ramgarhia](https://hazri.me/gurpurab/jassa-singh-ramgarhia) | [Ramgarhia_Bunga,_Golden_Temple,_Amritsar,_Punjab,_India_(2015).jpg](https://commons.wikimedia.org/wiki/File:Ramgarhia_Bunga,_Golden_Temple,_Amritsar,_Punjab,_India_(2015).jpg) |
| [jassa-singh-ahluwalia](https://hazri.me/gurpurab/jassa-singh-ahluwalia) | — (drawn illustration) |
| [sant-giani-kartar-singh-ji-bhindranwale](https://hazri.me/gurpurab/sant-giani-kartar-singh-ji-bhindranwale) | — (drawn illustration) |
| [harmandir-sahib-foundation-stone](https://hazri.me/gurpurab/harmandir-sahib-foundation-stone) | [Golden_Temple_-_Amritsar_-_Punjab_-_003.jpg](https://commons.wikimedia.org/wiki/File:Golden_Temple_-_Amritsar_-_Punjab_-_003.jpg) |
| [sri-akal-takht-sahib-foundation-day](https://hazri.me/gurpurab/sri-akal-takht-sahib-foundation-day) | [Photograph_of_the_Akal_Takht_in_Amritsar_from_circa_1870.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_the_Akal_Takht_in_Amritsar_from_circa_1870.jpg) |
| [sampuranta-divas-guru-granth-sahib-ji](https://hazri.me/gurpurab/sampuranta-divas-guru-granth-sahib-ji) | — (drawn illustration) |
| [guru-gobind-singh-ji-mata-jito-ji-marriage-guru-ka-lahore](https://hazri.me/gurpurab/guru-gobind-singh-ji-mata-jito-ji-marriage-guru-ka-lahore) | — (drawn illustration) |
| [basant-panchmi-sikh-history](https://hazri.me/gurpurab/basant-panchmi-sikh-history) | — (drawn illustration) |
| [victory-at-sirhind-chappar-chiri-1710](https://hazri.me/gurpurab/victory-at-sirhind-chappar-chiri-1710) | [Fateh_Burj_chappar_chiri.jpg](https://commons.wikimedia.org/wiki/File:Fateh_Burj_chappar_chiri.jpg) |
| [chhota-ghallughara-1746-kahnuwan](https://hazri.me/gurpurab/chhota-ghallughara-1746-kahnuwan) | — (drawn illustration) |
| [leaving-anandpur-sahib-fort-1704](https://hazri.me/gurpurab/leaving-anandpur-sahib-fort-1704) | [Anandapur_Sahib_Panorama_(1).jpg](https://commons.wikimedia.org/wiki/File:Anandapur_Sahib_Panorama_(1).jpg) |
| [parivar-vichhora-sirsa-river](https://hazri.me/gurpurab/parivar-vichhora-sirsa-river) | [Pariwar_vichhora_gurudwara.jpg](https://commons.wikimedia.org/wiki/File:Pariwar_vichhora_gurudwara.jpg) |
| [darbar-khalsa-dussehra](https://hazri.me/gurpurab/darbar-khalsa-dussehra) | — (drawn illustration) |
| [morcha-guru-ka-bagh-1922](https://hazri.me/gurpurab/morcha-guru-ka-bagh-1922) | — (drawn illustration) |
| [chabiyan-da-morcha-1922](https://hazri.me/gurpurab/chabiyan-da-morcha-1922) | [Photograph_of_the_square_in-front_of_the_Akal_Takht_in_Amritsar,_circa_1924.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_the_square_in-front_of_the_Akal_Takht_in_Amritsar,_circa_1924.jpg) |
| [jaito-da-morcha-1923-1925](https://hazri.me/gurpurab/jaito-da-morcha-1923-1925) | [Gangsar_Jaitu.jpg](https://commons.wikimedia.org/wiki/File:Gangsar_Jaitu.jpg) |
| [sardar-baghel-singh-delhi-1783](https://hazri.me/gurpurab/sardar-baghel-singh-delhi-1783) | [Photograph_of_Gurdwara_Sis_Ganj_Sahib_in_Chandni_Chowk,_Delhi,_ca.1913–16.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_Gurdwara_Sis_Ganj_Sahib_in_Chandni_Chowk,_Delhi,_ca.1913–16.jpg) |
| [vaisakhi-khalsa-saajna-divas](https://hazri.me/gurpurab/vaisakhi-khalsa-saajna-divas) | [Takht_Sri_Kesgarh_Sahib_-_Anandpur_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Takht_Sri_Kesgarh_Sahib_-_Anandpur_Sahib.jpg) |
| [bandi-chhor-divas](https://hazri.me/gurpurab/bandi-chhor-divas) | [Golden_Temple_Amritsar_Sarovar.JPG](https://commons.wikimedia.org/wiki/File:Golden_Temple_Amritsar_Sarovar.JPG) |
| [nanakshahi-new-year-chet-sangrand](https://hazri.me/gurpurab/nanakshahi-new-year-chet-sangrand) | — (drawn illustration) |
| [maghi-sri-muktsar-sahib-chali-mukte](https://hazri.me/gurpurab/maghi-sri-muktsar-sahib-chali-mukte) | [Gurudwara_Tooti_Gandi_Sahib,_Sri_Muktsar_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Gurudwara_Tooti_Gandi_Sahib,_Sri_Muktsar_Sahib.jpg) |
| [baba-bakala-rakhar-puniya-jor-mela](https://hazri.me/gurpurab/baba-bakala-rakhar-puniya-jor-mela) | [Gurdwara_Baba_Bakala_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Gurdwara_Baba_Bakala_Sahib.jpg) |
| [kandh-sahib-batala-guru-nanak-marriage](https://hazri.me/gurpurab/kandh-sahib-batala-guru-nanak-marriage) | [Kandh_Sahib.jpg](https://commons.wikimedia.org/wiki/File:Kandh_Sahib.jpg) |
| [chola-sahib-jor-mela-dera-baba-nanak](https://hazri.me/gurpurab/chola-sahib-jor-mela-dera-baba-nanak) | — (drawn illustration) |
| [miri-piri-divas](https://hazri.me/gurpurab/miri-piri-divas) | [Photograph_of_the_Akal_Takht_in_Amritsar,_ca.1920's.jpg](https://commons.wikimedia.org/wiki/File:Photograph_of_the_Akal_Takht_in_Amritsar,_ca.1920's.jpg) |
| [sikh-dastaar-divas-world-turban-day](https://hazri.me/gurpurab/sikh-dastaar-divas-world-turban-day) | [Sikh_wearing_turban.jpg](https://commons.wikimedia.org/wiki/File:Sikh_wearing_turban.jpg) |
| [india-independence-day-sikh-contribution](https://hazri.me/gurpurab/india-independence-day-sikh-contribution) | — (drawn illustration) |
| [partition-1947-ardas-day](https://hazri.me/gurpurab/partition-1947-ardas-day) | — (drawn illustration) |
| [punjabi-suba-day](https://hazri.me/gurpurab/punjabi-suba-day) | — (drawn illustration) |
| [sgpc-foundation-day](https://hazri.me/gurpurab/sgpc-foundation-day) | — (drawn illustration) |
| [shiromani-akali-dal-foundation-day](https://hazri.me/gurpurab/shiromani-akali-dal-foundation-day) | — (drawn illustration) |
| [sangrand](https://hazri.me/gurpurab/sangrand) | [Amrit_Sarovar_around_Golden_Temple_(Harmandir_Sahib),_Amritsar,_Punjab,_India_(2017).jpg](https://commons.wikimedia.org/wiki/File:Amrit_Sarovar_around_Golden_Temple_(Harmandir_Sahib),_Amritsar,_Punjab,_India_(2017).jpg) |
| [masya](https://hazri.me/gurpurab/masya) | — (drawn illustration) |
| [puranmashi](https://hazri.me/gurpurab/puranmashi) | — (drawn illustration) |
