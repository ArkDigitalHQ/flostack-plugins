---
description: Generate valid Schema.org JSON-LD structured data for a page to improve GEO and rich-result eligibility
argument-hint: "[URL, file path, or a description of the page/entity]"
---

# GEO Schema Generator

Generate valid, ready-to-paste Schema.org JSON-LD for the target. Correct
structured data is one of the highest-ROI moves for Generative Engine
Optimization — it tells answer engines exactly what each entity is.

**Target:** `$ARGUMENTS`

If no target was provided, ask what the page is about (page type, business/entity
name, key facts) before proceeding.

## Steps

1. **Determine the content.**
   - URL → fetch with WebFetch and infer entity facts from the page.
   - Local file → read it.
   - Description → use what the user gave; ask for any missing required fields.

2. **Pick the right schema type(s).** Choose what genuinely fits — don't
   over-mark. Common high-value types:
   - `Organization` / `LocalBusiness` — home/about pages.
   - `FAQPage` — any page with Q&A (highest GEO value; emit one `Question`
     per real Q&A pair found).
   - `Article` / `BlogPosting` — articles and posts (`author`, `datePublished`,
     `dateModified`).
   - `Product` / `Service`, `BreadcrumbList`, `HowTo`, `Person`, `WebSite`
     (with `SearchAction`) — where applicable.
   - Combine types with `@graph` when a page legitimately represents several.

3. **Generate the JSON-LD.**
   - Use real values from the content; for genuinely unknown required fields,
     insert a clearly-marked `"REPLACE_ME"` placeholder and list them after.
   - Include recommended properties, not just required ones (`sameAs`, `logo`,
     `image`, `url`, contact info, dates) where data exists.
   - Output a single `<script type="application/ld+json">` block per page,
     valid JSON, properly nested.

4. **Output:**
   - The ready-to-paste `<script>` block(s).
   - A short list of any placeholders the user must fill in.
   - A one-line reminder to validate with Google's Rich Results Test /
     Schema.org validator before shipping.

5. **Offer to insert** the block into the local file (in `<head>`) if applicable.

---

*Built by FloStack · custom AI workflows & integrations at [flostack.ca](https://flostack.ca/plugins)*
