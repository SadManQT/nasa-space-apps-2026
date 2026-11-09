# M1-121: every saved branch re-audited

Static baseline `5f6f1df9d4fecaf24901625e9a88bc2f5d7930a5`; metadata-only main merge `59382f1d42528e898df22c21b1d077728c1e8afb` has the same game tree.

Coverage: **62 refs, 57 unique tips**. All refs are indexed below: 12 ancestry-integrated, 36 superseded, 7 metadata-only and 7 unsafe WIP. The two parent expressions in review.json are supplemental inspections, not extra branches.

No branch was deleted, pruned, checked out or wholesale merged. Original checkout imports/settings and saved WIP remain protected. All incoming Asif/team-board edits were preserved.

## What to finish first

1. **M1-56 (Ramim): Messages inbox.** No audited branch contains a finished inbox. M1-69/M1-99 delivered its bounded save/retry interfaces; implement against current main.
2. **M1-112 (Ramim), M1-49 (Atik): real STACK entry and Care Round integration.** Chapter 1 clips include carrying/stacking and the care-round photo; saved provider code alone is not a usable player path.
3. **M3-2T/M3-3T/M3-4T (Ramim): missing chapter packs.** These also block Asif M3-75. Keep Sadman-authored packs intact.
4. Recheck M1-103 (Atik Class bridge), M1-105 (Atik chosen-input puzzle dispatch), and M1-120 (Sadman measured EVA preparation). Resume owned saved UI when contracts land.

**Clip gates:** M1-59 depends on M1-54(done), M1-55(blocked formal full-suite/M1-68 gate), M1-56(missing inbox) and M1-58(done). Mission Table exists and its lifetime fix is published; do not rebuild it. M3-66 additionally depends on M3-61/62/63/64/65 as well as M1-59. M3-76 follows M3-66. These video tasks remain Sadman-owned.

**Saved-work decisions:** retain P01/credits/Watch/contrast branches as history: their source is already ported or superseded. Never port the old P01 private-receipt deletion or answer-prefill route, the old snapshot-based Class setter, ScientificPuzzlePanel class collisions, incomplete watchdog, or .night_merge debris. M1-37 needs M1-103, not the already-delivered M1-102. M3-2P needs M1-105, not the already-delivered M1-104. M1-95 and M1-115 source is delivered; their remaining acceptance gate is not missing source (this corrects shorthand in the preserved Ramim reviewer notes).

**Verification limits:** this is a Git/tree/code/LFS-pointer audit, not a fresh runtime or asset-render pass. Historical evidence is not current acceptance. Prior full run e78/game108a was 83/84, with only performance M1-68 failing; newer M1-118 focused358/0 and native14/0 do not constitute a fresh full run. No release-ready or all-tests-green claim.

## Complete ref index

| Ref at snapshot | SHA | Classification |
|---|---|---|
| `refs/heads/backup/pre-sync-20261104-69c4283c` | `ff09cfd33bb147811a812e0a7ccae7b525b916b2` | ancestry-integrated |
| `refs/heads/main` | `5f6f1df9d4fecaf24901625e9a88bc2f5d7930a5` | ancestry-integrated |
| `refs/heads/ramim/atik-label-20261109` | `5f6f1df9d4fecaf24901625e9a88bc2f5d7930a5` | ancestry-integrated |
| `refs/heads/ramim/continue-20261106` | `afe0c747aa89f8d72bc99c3c2512b4b18bf97a04` | superseded |
| `refs/heads/ramim/continue-20261108` | `948ef2f024dd8c7b553bffe4be3271ee2b01830b` | superseded |
| `refs/heads/ramim/m108-await-runtime-20261108` | `afe0c747aa89f8d72bc99c3c2512b4b18bf97a04` | superseded |
| `refs/heads/ramim/m108-ui-review-20261109` | `948ef2f024dd8c7b553bffe4be3271ee2b01830b` | superseded |
| `refs/heads/ramim/m170-full-20261108` | `defddc9fc218c58ed1517d5240904c24ef4fd989` | superseded |
| `refs/heads/ramim/m172-postpull-validated-20261108` | `7ff8f61edb6b28a60d1df11cf5d33d47b1c2abb3` | superseded |
| `refs/heads/ramim/m172-validated-20261108` | `0fbfeac5ae920e5f2ac66e78eff1a28de1f14d31` | superseded |
| `refs/heads/ramim/m175-validated-20261109` | `c33c19912d96338e174fc9a8c7474cc1dba1d075` | superseded |
| `refs/remotes/origin/HEAD` | `5f6f1df9d4fecaf24901625e9a88bc2f5d7930a5` | ancestry-integrated |
| `refs/remotes/origin/main` | `5f6f1df9d4fecaf24901625e9a88bc2f5d7930a5` | ancestry-integrated |
| `refs/remotes/origin/night/M1-03` | `f7ec969f7f322ad326402b1c2a4b238d0f6326cd` | superseded |
| `refs/remotes/origin/night/M1-05` | `574dda3ac06d1bf71b841f655eb5cb94dd1bacf7` | superseded |
| `refs/remotes/origin/night/M1-06` | `1158f837d011dba5780e1f9f64b56934cfdff226` | superseded |
| `refs/remotes/origin/night/M1-07` | `a7140a30e37c50cd11fab9bb95dbad6951ba1092` | superseded |
| `refs/remotes/origin/night/M1-08` | `1f01baaa88ee0945de826b6ad7d7763b8bfe5b08` | unsafe-WIP |
| `refs/remotes/origin/night/M1-100` | `b276bb4d3b85190cff296c3e191752a41ec3e553` | superseded |
| `refs/remotes/origin/night/M1-18` | `29877b8f739be0a12c9324bcdc0d7067a1bac8af` | metadata-only |
| `refs/remotes/origin/night/M1-19` | `8a253dd7f8cbf488f98f259c23e5c073a2ad55d1` | ancestry-integrated |
| `refs/remotes/origin/night/M1-19-saved` | `3f67b0111292438a40248f4ff977f0b839098179` | superseded |
| `refs/remotes/origin/night/M1-29` | `a1e0a6ce6572ce8112eab988f0cc48ef6c37196d` | ancestry-integrated |
| `refs/remotes/origin/night/M1-34` | `fece37e293b3063de41818a3b89111b52544bbd9` | superseded |
| `refs/remotes/origin/night/M1-37` | `8a792c11cd549a8fe1b0d2c5568101c31ef2bf5e` | unsafe-WIP |
| `refs/remotes/origin/night/M1-47` | `467a16f7458da2401d85fd9a79ad7f0846ad108e` | superseded |
| `refs/remotes/origin/night/M1-49` | `2158d1c7c88a931b7a738a56e20b0c13f6e8608d` | metadata-only |
| `refs/remotes/origin/night/M1-50` | `0c79ea7b4b28ec9a74b441f0957ae631cae3dda9` | metadata-only |
| `refs/remotes/origin/night/M1-51` | `0eb7f7c2b50c79b18086bcba0238b60a0e853669` | superseded |
| `refs/remotes/origin/night/M1-52` | `88301efda7a8cbd9a344e4049503caabd81e1216` | metadata-only |
| `refs/remotes/origin/night/M1-53` | `f6285e46eabae8e02274cffac9d53f9e31fb3209` | unsafe-WIP |
| `refs/remotes/origin/night/M1-54` | `e83b8836c4af6d33e87df9973e5c30e907e0f067` | superseded |
| `refs/remotes/origin/night/M1-58` | `53d5fff1ffa063f9cc0d91525ba2851a3030f145` | unsafe-WIP |
| `refs/remotes/origin/night/M1-76` | `b38ac3d3feecd4a7ff6a5a7db897fe8994f5707e` | superseded |
| `refs/remotes/origin/night/M1-81` | `4c5e4e18f4aa5fc8b03bebfcb63d3b6036c62c6c` | metadata-only |
| `refs/remotes/origin/night/M1-86` | `1bc7813455fff5fbdae4bfcc10fbd294f78d1424` | metadata-only |
| `refs/remotes/origin/night/M1-87` | `8bd450fd2e8dd1046bdfa29ccf488c2bda9a2399` | superseded |
| `refs/remotes/origin/night/M1-89` | `59ab82ea88b9462c51a067c3c097a7d0312dd193` | superseded |
| `refs/remotes/origin/night/M1-91` | `e2336d4118f16cfc5d9acfd6f4e535f5ab00789a` | superseded |
| `refs/remotes/origin/night/M1-96` | `879b67afce66e508290c3b3889b5db183a701f0f` | metadata-only |
| `refs/remotes/origin/night/M3-104` | `27a573915bf759fc115cb9c2e51a908504d1774d` | superseded |
| `refs/remotes/origin/night/M3-108` | `5803b88862bcc57c661a3aaec374187d9203f404` | superseded |
| `refs/remotes/origin/night/M3-2A` | `8907a1f72cee598fa64c03df0b5dd9d3605ac615` | superseded |
| `refs/remotes/origin/night/M3-2P` | `5203a6fb1a3f4dfbc975e489ecc25e278e776b36` | unsafe-WIP |
| `refs/remotes/origin/night/M3-2R` | `b91078e8140715d69fb69c988d899f71481c02e0` | superseded |
| `refs/remotes/origin/night/M3-3A` | `6246460adadd9d37377cc9f694082c9097323bdf` | superseded |
| `refs/remotes/origin/night/M3-3P` | `704baf3ffc5f48d60e5a13f37545793761524341` | unsafe-WIP |
| `refs/remotes/origin/night/M3-4P` | `f815b1a19aeb3d9ed2b15e9819cacbc69dbd6aa1` | ancestry-integrated |
| `refs/remotes/origin/night/M3-5A` | `a1672162d179657d9d2596ed33f57b862b36a858` | superseded |
| `refs/remotes/origin/night/M3-5P` | `3a1112e98d9b9eb8894ad69121562d85b907bdd9` | ancestry-integrated |
| `refs/remotes/origin/night/M3-6P` | `d04968d21fbd284050f0f9894c51abda96cf6f02` | ancestry-integrated |
| `refs/remotes/origin/night/M3-6R` | `cd547b114db180c2525f20f870a23240a20f30f6` | superseded |
| `refs/remotes/origin/night/M3-7A` | `0f2396f52b7709c17615b1c5ad603b6fdbe9b8e3` | superseded |
| `refs/remotes/origin/night/M3-7P` | `d503b42e62cecc8c0be51f18b79a9fb1fd5cdae0` | ancestry-integrated |
| `refs/remotes/origin/night/M3-8P` | `9a83b6822144c1c3a1b157a0cb240468fcb4b0a6` | unsafe-WIP |
| `refs/remotes/origin/night/M3-94` | `c81b8eb0aeba2377109e2b77b530d26c9e07aea5` | superseded |
| `refs/remotes/origin/night/M3-97` | `5051d6494b3f6fd8b6aaa0646d1749c406420542` | superseded |
| `refs/remotes/origin/night/M3-99` | `a41b57155fa422b9e00daa29ac6da53e634cbd86` | ancestry-integrated |
| `refs/remotes/origin/night/M3-99-saved` | `33ffca653ac6ce2347aa956015402dccf05ff5c2` | superseded |
| `refs/remotes/origin/night/M4-02` | `7549dfc13addf54192148dd3810e5247ddaf57bb` | superseded |
| `refs/remotes/origin/night/M4-05` | `f484b2caf656c3abae78941c4338f1885ca9c09f` | superseded |
| `refs/remotes/origin/sadman/m110-m111-media` | `6b7054dd9112f25982af9ff1ab2d446ea65ca24e` | superseded |

## Evidence map

- `inventory.json`: every ref, merge base, ancestry, ahead/behind, changed paths and exact blob adoption.
- `review.json`: one normalized decision per ref; findings, reusable paths, dependencies, resume action and limits. Dependencies specify owner/task; unblocked refs have an empty dependency list.
- Three preserved reviewer Markdown reports: detailed static findings and source references.
- `SHA256.json`: full-byte public artifact fingerprints.
