# AGENTS.md

How we build and maintain LAB663. Whether you're a person or an agent
helping us, these are the ground rules.

## How we teach

We climb the hill together: build it, measure it, improve it.

- **One lever at a time.** Each change (model, prompt, router edition) is
  made and measured on its own, so we know what moved the score.
- **Evidence before opinion.** We look at the trace, the eval or the insight
  first, then decide what to change.
- **Frozen measuring stick.** The eval set and rubric don't change between
  versions, so every score is comparable.
- **Build, break, fix, learn.** Every module ends with something we built,
  broke on purpose or by accident, fixed, and can explain.
- **Time budget.** The slowest learner finishes the core modules in 60
  minutes. Fast learners get the bonus labs.

## How we write

Full guide: [workshop-content.instructions.md](.github/instructions/workshop-content.instructions.md). The short version:

- Write like a colleague at a whiteboard: friendly, concise, practical, curious. Use "we" and "let's".
- No marketing language ("unlock", "seamlessly", "leverage"). Plain words, no jargon without a definition.
- Teach in this order: problem, idea, see it, try it, what happened, why it matters, go further.
- For each concept, give a business lens (why use it?) and an engineering lens (how does it work?).
- Be honest about limits and rough edges. Never invent numbers.
- Use visuals sparingly: a diagram, table or chart where it explains faster than words, never as decoration.
- Keep the climbing metaphor light: versions, altitude, the hill.
- Sentence-case headings. Every step ends with a visible expected result.

## Two delivery modes

- **Self-guided** (`instructions/self-guided/`): our own subscription,
  we deploy with `infra/deploy.sh`.
- **Skillable** (`instructions/skillable/`): infrastructure is
  pre-provisioned. Never mix the two. When shared setup changes, update both.

## Ground rules

- Never commit secrets, `.env` files or PII.
- Don't edit `LICENSE`, `LICENSE-DOCS`, `CODE_OF_CONDUCT.md` or `SECURITY.md`.
- Attribute the TrailMate data (see `data/PROVENANCE.md`).
- Check with the content owners before adding third-party content.
