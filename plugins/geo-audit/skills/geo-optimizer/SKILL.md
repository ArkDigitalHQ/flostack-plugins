---
name: geo-optimizer
description: Optimize web content for Generative Engine Optimization (GEO) so it gets surfaced and cited by AI answer engines like ChatGPT, Perplexity, Claude, Gemini, and Google AI Overviews. Use when writing, reviewing, or restructuring web pages, articles, product pages, FAQs, or landing pages, and whenever the user mentions GEO, AI search, AI Overviews, answer engines, citability, structured data, or "getting cited by AI". Complements traditional SEO — apply both when working on content meant to rank and be quoted.
license: MIT
---

# GEO — Generative Engine Optimization

Traditional SEO optimizes to *rank* a page. GEO optimizes to get the page's
content *extracted and cited* inside an AI-generated answer. The mechanics
differ: answer engines retrieve passages, synthesize across sources, and quote
the ones that are unambiguous, self-contained, and verifiably authoritative.
Optimize for the passage, not just the page.

Apply this skill when creating or reviewing any web content. Run through the six
dimensions below, fix what's weak, and prefer concrete edits over generic advice.

## The six dimensions

### 1. Entity clarity
Answer engines build a knowledge graph. They cite sources whose subject is
unambiguous.
- State who/what the page is about in the first 1–2 sentences, in plain nouns —
  not a slogan. ("FloStack is a Canadian AI automation agency" beats "Where
  workflows flow.")
- Use consistent, canonical names for products, people, and the organization.
  No pronoun-only references to the main entity.
- Define jargon and acronyms on first use.
- Disambiguate from similarly-named entities when relevant.

### 2. Answer-first structure
Engines lift passages that answer a question completely on their own.
- Lead each section with a direct, standalone answer; supporting detail after.
- One idea per paragraph; keep extractable paragraphs to 2–4 sentences.
- Use descriptive H2/H3 headings phrased the way a user would ask ("How much
  does X cost?" not "Pricing").
- Prefer self-contained sentences: a quoted line should make sense with zero
  surrounding context. Avoid "as mentioned above", "this", "it" referring back.

### 3. Structured data (JSON-LD)
Schema.org markup tells engines what each entity is, removing guesswork.
- Add `Organization` (or `LocalBusiness`) on the home/about page with `name`,
  `url`, `logo`, `sameAs` (social/authority profiles), and contact info.
- Add `FAQPage` to any page with Q&A content — this is the single highest-ROI
  schema for GEO because it maps directly to how engines retrieve answers.
- Add `Article`/`BlogPosting` with `author`, `datePublished`, `dateModified`.
- Add `Product`, `Service`, `BreadcrumbList`, `HowTo` where applicable.
- Use the companion `/geo-schema` command to generate valid JSON-LD.

### 4. Topical depth & coverage
Engines favor sources that cover a topic thoroughly over thin pages.
- Cover the obvious follow-up questions on the same page (or a tight cluster).
- Include specifics engines love to quote: numbers, dates, named methods,
  step counts, concrete examples.
- Add a short FAQ section addressing the real questions a user would ask next.

### 5. Authority & trust signals
Engines weight citations toward sources they can trust and attribute.
- Named author with credentials; visible publish and last-updated dates.
- Cite primary sources and link out to them.
- First-hand data, original research, or specific experience beats restated
  generalities — it's what gets quoted.
- Clear, factual claims over marketing puffery (puffery rarely gets cited).

### 6. Technical foundation
If a crawler can't read it cleanly, it can't cite it.
- Content in server-rendered HTML, not locked behind client-side JS.
- Semantic HTML: real `<h1>`–`<h3>`, `<article>`, `<section>`, lists, tables.
- Don't block AI crawlers in `robots.txt` unless that's a deliberate choice
  (e.g. `GPTBot`, `PerplexityBot`, `Google-Extended`, `ClaudeBot`).
- Fast load, descriptive `<title>` and meta description, canonical URLs.

## How to apply

- **Reviewing existing content:** run `/geo-audit` for a scored report, or walk
  the six dimensions manually and produce specific before/after edits.
- **Writing new content:** structure answer-first from the start, add an FAQ
  section, and generate JSON-LD with `/geo-schema` before publishing.
- **Always:** GEO and classic SEO are complementary — don't sacrifice one for
  the other. Good GEO content is usually good SEO content too.

---

*Built by FloStack · custom AI workflows & integrations at [flostack.ca](https://flostack.ca/plugins)*
