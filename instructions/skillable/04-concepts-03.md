# 4.3 Let a router choose

**What we'll do:** Send the same two questions to a **model router** and see which model it picks for each.

> [!Knowledge] A **model router** is one deployment that looks at each request and sends it to a model from a pool. Easy work can go to a small model, and hard work to a bigger one.

1. [] Close the gpt-5.4-mini pane with its **X**. In the remaining pane, open the **Model** menu and select **mr-default**.

    <!-- VERIFY: how to switch deployments in the playground -->

1. [] Send the easy daypack question again.

    ++TrailLite Daypack specs: Weight 1.5 lbs, Dimensions 20in x 12in x 6in, Water-resistant fabric. How much does the TrailLite Daypack weigh?++

1. [] Find which model answered. Look in the response details for the **model** name.

    <!-- TODO screenshot: 04-concepts-03-router-easy.png | Router response details showing the model chosen for the easy question -->
    <!-- VERIFY: where the playground shows the routed model -->

1. [] Send the harder tent question and find which model answered it.

    ++TrailMaster X4 Tent: 4-person, 12 lbs, $250, rainfly rated 2000mm. Alpine Explorer Tent: 8-person, 17 lbs, $350, rainfly rated 3000mm. A family of six is camping in heavy rain, wants the lightest setup possible, and has a tight budget. Weigh the trade-offs and recommend one.++

    <!-- TODO screenshot: 04-concepts-03-router-hard.png | Router response details showing the model chosen for the hard question -->

> [+Hint] Ask Copilot: how does a router choose?
>
> ++How does Microsoft Foundry model router decide which model answers a request? Explain in two sentences.++

---

> [!Note] **Success:** We just watched one deployment pick a model per question, without us choosing.
