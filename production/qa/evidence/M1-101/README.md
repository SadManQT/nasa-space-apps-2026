# M1-101 ? HUD world-node lifetime

9 November2026, Ramim. Source3d03159 plus review fix da1bbc6.

Shared HUD distance readers reject detached/freed target or player; world overlays stay hidden until the player and marker are inside the real tree. Valid world geometry remains unchanged. No runtime/world/asset/audio change.

Real CampaignScene regression detaches/re-adds the real target/player, verifies literal3-4-5 horizontal distance, and rebuilds two real rooms. RED12/4 with detached-transform errors; GREEN12/0, `1/1 suites passed`. Final GREEN runs on main-derived HUD+this guard alone, separately from the saved P01 UI work. Original RED had the saved P01 hookup present; the same guard defects were reproduced in prior main P01inputs logs too.

The known detached-transform errors disappear. A separate audio_director.gd:303 suspended _stream resumes after its owner is freed, logging ERROR and1 ObjectDB warning in both runs. Source owner is Sadman; a board request is filed with this exact reproduction. It is not hidden or called fixed. The general runner reports suite assertions; its passing line does not mean every engine diagnostic is clean.

Full integrated runner and native visible marker verification remain pending the batch/P01 integration. The complete saved P01 HUD is preserved privately before/with this same guard; no unfinished work discarded.

Independent review found1 Important gap in the nearby-prompt path. Added a real detached CampaignRoom.focus_root child regression:RED13/1; guarded that shared reader; final13/0. Existing P01inputs317/0 on final da1bbc6 also emits no detached-transform errors. Final focused total330 checks, zero failures. Review finding addressed in one RED/GREEN fix pass; no rereview claimed. Audio error/1ObjectDB warning persists in lifecycle fixture (M1-114); P01inputs still warns4ObjectDB instances. Native/full still pending.
