Require Import MetaCoq.MetaCoq.

Require Import Bool.Bool.

Definition anat : nat.
MProof.
  _ <- evar nat; ret 0.
Fail Qed.