# Skillable test walkthrough

This is our working log from testing LAB663 on Skillable. We record each command we ran, what we saw and any fixes we needed. Later we'll turn it into the Skillable learner instructions.

Screenshots live in [screenshots/](./screenshots/).

## How we're testing

| Phase | What we're checking | How |
|---|---|---|
| Phase one | The Skillable subscription has everything the lab needs | Follow the self-guided path with the Skillable account, deploying with `infra/deploy.sh` ourselves |
| Phase two | The Skillable VM's pre-provisioned subscription works for learners | Follow only the steps that apply to the pre-provisioned environment |

Starting point: commit `526d3f6` ("Clearing before Skillable test") on `nitya/oct16-test`. Notebooks cleared, no `.env`, no saved lab state, signed out of Azure.

## Phase one: validate the Skillable subscription

### Environment

| Item | Value |
|---|---|
| Date | 2026-10-18 |
| Branch | `nitya/oct16-test` |
| Subscription | _To record_ |
| Account used | _To record_ |
| Region | _To record_ |
| Resource group | _To record_ |

### Steps

_We add each step here as we go: the command, what we expected, what happened and a screenshot when it helps._

## Phase two: validate the pre-provisioned VM

_Not started._

## Troubleshooting log

_We record every problem here: what we saw, the cause and the fix. Each entry notes whether the Skillable instructions need to change._
