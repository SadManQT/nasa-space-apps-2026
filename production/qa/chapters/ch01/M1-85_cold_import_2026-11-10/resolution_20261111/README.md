# M1-85 resolution checkpoint - 11 November 2026

In progress; no new native-crash cause or completed engine matrix is claimed.

The actual shell runner now rejects setup ERROR diagnostics even when Godot exits zero, retains setup/suite raw exit files, and preserves the existing script/native/timeout behavior. Actual-shell regressions: 11 methods passed, one POSIX-only signal fixture skipped on Windows; see [unit_runner.txt](unit_runner.txt).

The scoped Game attribute rule keeps import sidecars LF across Windows checkout. [canonical_metadata.json](canonical_metadata.json) records 2939 already-LF canonical blobs, so no asset parameter or bulk metadata rewrite is included.

The retained original-source A/B replay is running in ignored isolated projects. Its code and new native font probe will be published with actual evidence after validation. Current-source mandatory/full checks and upstream handoff remain pending. The historical native exit139 remains unexplained. M1-122/M1-123 remain completed, and no new movement/collision changes are included. Manual QA/videos remain deferred.
