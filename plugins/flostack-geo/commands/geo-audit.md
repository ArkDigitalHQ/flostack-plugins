---
description: Audit a web page or content file for Generative Engine Optimization (GEO) and produce a scored report with specific fixes
argument-hint: "[URL or path to .html/.md/.mdx file]"
---

# GEO Audit

Audit the target for Generative Engine Optimization — how likely its content is
to be surfaced and cited by AI answer engines (ChatGPT, Perplexity, Claude,
Gemini, Google AI Overviews).

**Target:** `$ARGUMENTS`

If no target was provided, ask the user for a URL or a local file path before
proceeding.

## Steps

1. **Load the content.**
   - If the target is a URL, fetch it with WebFetch and analyze the rendered
     content. Note if critical content appears to require client-side JS.
   - If it's a local file, read it directly.
   - If it's a directory, audit the most important page (home/index) and offer
     to audit others.

2. **Score each dimension 0–5** (0 = absent, 5 = excellent). Be a strict,
   specific critic — cite actual text from the page, not generalities.
   - **Entity clarity** — is the subject named unambiguously up top, with
     consistent canonical naming and defined jargon?
   - **Answer-first structure** — do sections lead with standalone answers?
     Are paragraphs short and self-contained? Are headings phrased as questions?
   - **Structured data** — is there valid JSON-LD? Which schema types are
     present vs. missing (Organization, FAQPage, Article, Product, etc.)?
   - **Topical depth** — does it cover follow-up questions, with quotable
     specifics (numbers, dates, named methods, examples)?
   - **Authority signals** — named author, visible dates, cited sources,
     first-hand data?
   - **Technical foundation** — server-rendered HTML, semantic structure,
     crawlable, descriptive title/meta?

3. **Output the report** in this format:

   ```
   GEO Audit — <target>
   Overall: XX/30  (<one-line verdict>)

   Dimension            Score   Notes
   Entity clarity        x/5    ...
   Answer-first          x/5    ...
   Structured data       x/5    ...
   Topical depth         x/5    ...
   Authority             x/5    ...
   Technical             x/5    ...

   Top fixes (highest impact first):
   1. <specific, actionable fix with the exact text/section to change>
   2. ...
   3. ...
   ```

4. **Make fixes concrete.** Each recommendation must name the section and show a
   before/after where possible. For missing structured data, offer to generate
   it with `/geo-schema`.

5. **Offer to apply** the top fixes if the target is a local file the user can
   edit.

---

*Built by FloStack · custom AI workflows & integrations at [flostack.ca](https://flostack.ca/plugins)*
