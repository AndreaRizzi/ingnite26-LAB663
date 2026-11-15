# 3.1 Compare a big and a small model

**What we'll do:** Send the same two questions to a big and a small model, and see how model choice changes speed, tokens, and quality.

1. [] In Edge, switch to the **Foundry portal** tab we opened on page 0.1 and select the **trailmate** project.
1. [] Open the model playground for **gpt-5.4** and turn on **Compare** with **gpt-5.4-mini**.

    <!-- TODO screenshot: 03-concepts-01-compare-setup.png | The model playground in compare view with gpt-5.4 and gpt-5.4-mini -->
    <!-- VERIFY: exact navigation to the model playground and the Compare button -->

1. [] Send this easy question.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Send this harder question. Watch for the trap: one TrailMaster X4 can't sleep six.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

1. [] Compare the two answers, response times, and token counts.

    <!-- TODO screenshot: 03-concepts-01-compare-answers.png | Both models answering the tent question, with time and tokens visible -->

> [!Knowledge] The best answer is one Alpine Explorer: two X4s weigh 24 lbs and cost $500. Did the small model catch that? The real question isn't "which model is best?" but "which questions need the big one?"

---

> [!Note] **Success:** We just saw that a small model can be faster and cheaper, and where it can fall short.
