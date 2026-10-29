<p align="center">
  <img src="./assets/banners/00-set-the-stage.svg" alt="More Labs · Model Fundamentals — One tent, one launch: What can MAI models do for a real product launch? Microsoft Ignite 2026 · LAB 663" width="900" />
</p>

# Model Fundamentals: Explore Microsoft AI Models

> **What can MAI models do for a real product launch?**

Contoso Outdoors is going through an AI transformation. In the core lab, we make their chatbot, TrailMate, measurably better. Here, we help the rest of the business: marketing is relaunching the **TrailMaster X4** tent, and the website that hosts TrailMate needs a refresh.

Each notebook gives one job to one Microsoft AI (MAI) model family, and answers the questions a customer would ask about it. Where a model comes in a standard and a **Flash** version, we try both and decide which job needs which.

<br/>

## The notebooks

| # | Notebook | The question | Models |
| --- | --- | --- | --- |
| 00 | [Set the stage](./00-set-the-stage.ipynb) | What can MAI models do for a real product launch? | None. The story, the launch kit, and how to use these labs |
| 01 | [Build the launch kit](./01-build-launch-kit.ipynb) | How can MAI-Image-2.6 models support a real product launch? | MAI-Image-2.6, MAI-Image-2.6-Flash |
| 02 | [Give it a voice](./02-give-it-a-voice.ipynb) | How can MAI-Voice-2.1 models give a launch its voice? | MAI-Voice-2.1, MAI-Voice-2.1-Flash |
| 03 | [Hear your customers](./03-hear-your-customers.ipynb) | How can MAI-Transcribe-2 turn launch audio into answers? | MAI-Transcribe-2 |
| 04 | [Refresh the storefront](./04-refresh-the-storefront.ipynb) | Can a coding model turn our napkin sketch into a website? | The latest MAI-Code-X.Y-Flash in GitHub Copilot (may be in preview) |

Each one stands alone, but they tell one story in order: the pictures from 01 become the radio ad in 02, the ad is checked in 03, and 04 puts it all on the new launch page.

<br/>

## Read now, run later

Every notebook comes **pre-run**. Open it and read the saved results; you don't need Azure, and nothing costs money. That's a good way to spend the waits in the core lab.

Each notebook shows two times:

- **Review time:** how long it takes to read through the saved results.
- **Run time:** how long a fresh live run takes, including rate-limit waits.

Run them live **at home**, with no time pressure, or **in the venue** if you finish the core lab early.

<br/>

## Run it live

1. **Deploy.** If you ran `bash infra/deploy.sh` for the core lab, you're set: it deploys MAI-Image-2.6 and Flash, gives you access to MAI voice and transcription, and writes the settings to the repo's `.env`. Use `eastus` or `westus`.
2. **Switch to live.** Copy `.env.example` to `.env` in this folder, and set `DEMO_MODE=live`.
3. **Run the cells in order** with **Shift + Enter**.

Your pictures, audio and site files are saved under `output/`, which Git ignores. Replay mode shows yours first, then ours from `examples/`.

> **Skillable:** the guided environment doesn't include the image models yet. Read the saved results there, and run live at home.

<br/>

## Honest notes

| Note | What it means for you |
| --- | --- |
| **Release status varies** | MAI-Image-2.6 and Flash are generally available in Foundry. MAI-Voice-2.1 and Flash are in preview, and the MAI-Code Flash model in Copilot may be too. Check the model cards before production promises |
| **Every run is different** | Your pictures and audio won't match ours. Judge them with each section's checklist, not by matching ours |
| **Text and speech are English-first** | Have a native speaker check other languages |
| **You pay per use** | Per picture, per character spoken and per hour transcribed. See [MAI pricing](https://aka.ms/MAIModelPricing) and [Speech pricing](https://aka.ms/SpeechPricing) |

<br/>

## What's in this folder

| Path | What it is |
| --- | --- |
| `00-…ipynb` to `04-…ipynb` | The notebooks |
| `.env.example` | Settings for live runs |
| `assets/` | Banners, the section banners, and the napkin sketches |
| `examples/` | Saved results from our runs, used in replay mode |
| `output/` | Your own results from live runs. Git ignores it |

Contoso Outdoors is a made-up company. Its product data comes from [Azure-Samples/contoso-web](https://github.com/Azure-Samples/contoso-web) (MIT); see [data/PROVENANCE.md](../../data/PROVENANCE.md).
