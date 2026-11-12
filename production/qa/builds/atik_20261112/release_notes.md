Last Light Academy — full-game judging candidate for The Last BrainCell’s NASA Space Apps Challenge 2026 project. Contains Chapters 1–8. This is a pre-release pending final learner/controller and campaign QA.

Frozen source: `817a6eea2919440530c619614c7c8b87190bde1b` · Godot 4.7.2. The in-app version label remains `0.1.0-preview.20261105`; use the source commit and candidate_manifest.json to identify this build.

Download the Windows x86_64 or universal macOS ZIP below. Windows: unzip, keep the EXE and PCK together, run LastLightAcademy.exe. macOS: unzip and open the app; it is unsigned/unnotarized, so Privacy & Security may offer Open Anyway after the first launch attempt. WASD moves, mouse looks, E interacts, Esc pauses; captions and enlarged text are in Settings.

Both packaged executables pass **11 startup checks with zero failures** on fresh [Windows/macOS runners](https://github.com/SadManQT/nasa-space-apps-2026/actions/runs/43237871699). Local M4 foreground rendering also passes 11/0 and shows the actual Chapter 1 world. Runtime assets and science fixtures are included. The ZIPs contain current credits and the supplied UI font/gohud notices. SHA256SUMS.txt and candidate_manifest.json identify the exact packages and source.

Validation is reported precisely: the retained default full run is **136/138**. One failure is a media-test comparison of a regenerated save timestamp; the other is the 300-second full-campaign text-walk process cap. A separate documented 1,500-second text run passes **13048/0**; all 128 upgrade profiles pass **130308/0** over 96 route scenes. A media fixture correction is saved for owner review, not applied or counted as a repair. Raw logs and the complete qualification report are in the evidence ZIP.

Known limits: Mac first-use rendering/loading hitches remain under investigation; stable 60 fps and current weakest-laptop performance are not certified. Four-player Class mode and learner/controller/full-campaign acceptance remain in progress. This candidate does not certify those requirements or a final build freeze. An independent team project; not NASA-endorsed.
