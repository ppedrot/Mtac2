From MetaCoq
Require Export MetaCoq.

Require Import Strings.String.

Require Import Lists.List.
Import ListNotations.

Definition assert_eq {A} (a b : A) := mmatch a with b => ret I | _ => raise exception end.

(* Abstracting an index works *)
Goal True.
  mrun (nu x:nat, r <- abs (P:=fun _ :nat=>nat) x x; assert_eq r (@id nat)).
Qed.

(* Abstracting the second index works too *)
Goal True.
  mrun (nu y:nat, nu x:nat, r <- abs x x; assert_eq r (@id nat)).
Qed.

(* Abstracting the second index works too having names *)
Goal forall n m:nat, True.
  intros.
  mrun (nu y:nat, nu x:nat, r <- abs x x; assert_eq r (@id nat)).
Qed.

(* Abstracting the first index works too having names *)
Goal forall n m:nat, True.
  intros.
  mrun (nu x:nat, nu y:nat, r <- abs x x; assert_eq r (@id nat)).
Qed.

(* Abstracting a name works *)
Goal forall n m:nat, True.
  intros n m.
  mrun (r <- abs n n; assert_eq r (@id nat)).
Qed.

(* Abstracting a name works with indices too *)
Goal forall n m:nat, True.
  intros n m.
  mrun (nu x:nat, nu y :nat, r <- abs n n; assert_eq r (@id nat)).
Qed.

(* Abstracting an index depending on names works *)
Goal forall n m:nat, True.
  intros n m.
  mrun (nu H: n=m, r <- abs H H; assert_eq r (@id _)).
Qed.

(* Abstracting a name with an index depending on it works if the return value does not *)
Goal forall n m:nat, True.
  intros n m.
  mrun (nu H: n=m, r <- abs n n; assert_eq r (@id _)).
Qed.

(* Abstracting a name with an index depending on it does not work if the (type of the)
   return value depends on it *)
Goal forall n m:nat, True.
  intros n m.
  Fail mrun (nu H: n=m, r <- abs (P:=fun n'=>n'=m) n H; ret I).
Abort.

(* No dependency in the term should raise no problem *)
Goal True.
  mrun (nu x:nat, r <- abs (P:=fun _ :nat=>nat) x 0; assert_eq r (fun _=>0)).
Qed.

(* Abstracting a term depending on the return element is fine (the other way around is the problem) *)
Goal forall x, x>0 -> True.
  intros x H.
  mrun (r <- abs (P:=fun _:x >0=>nat) H x; assert_eq r (fun _=>x)).
Qed.

(* Evars prevent abstracting of a var *)
Goal forall A (x : A), True.
  intros A x.
  Fail mrun (e <- evar True; r <- abs A e; ret e).
Abort.