From Mtac2
Require Import Base.
Import M.
Import M.notations.

Require Import Strings.String.

Require Import Lists.List.
Import ListNotations.

Definition assert_eq {A} (a b : A) : M True := mmatch b with a => M.ret I | _ => M.raise exception end.

(* Abstracting an index works *)
Goal True.
  pose (code := (\nu x:nat, r <- M.abs_fun (P:=fun _ :nat=>nat) x x; assert_eq r (@id nat))%MC).
  mrun code.
Qed.

(* Abstracting the second index works too *)
Goal True.
  mrun (\nu y:nat, \nu x:nat, r <- M.abs_fun x x; assert_eq r (@id nat))%MC.
Qed.

(* Abstracting the second index works too having names *)
Goal forall n m:nat, True.
  intros.
  mrun (\nu y:nat, \nu x:nat, r <- M.abs_fun x x; assert_eq r (@id nat))%MC.
Qed.

(* Abstracting the first index works too having names *)
Goal forall n m:nat, True.
  intros.
  mrun (\nu x:nat, \nu y:nat, r <- M.abs_fun x x; assert_eq r (@id nat))%MC.
Qed.

(* Abstracting a name works *)
Goal forall n m:nat, True.
  intros n m.
  mrun (r <- M.abs_fun n n; assert_eq r (@id nat))%MC.
Qed.

(* Abstracting a name works with indices too *)
Goal forall n m:nat, True.
  intros n m.
  mrun (\nu x:nat, \nu y :nat, r <- M.abs_fun n n; assert_eq r (@id nat))%MC.
Qed.

(* Abstracting an index depending on names works *)
Goal forall n m:nat, True.
  intros n m.
  mrun (\nu H: n=m, r <- M.abs_fun H H; assert_eq r (@id _))%MC.
Qed.

(* Abstracting a name with an index depending on it works if the return value does not *)
Goal forall n m:nat, True.
  intros n m.
  mrun (\nu H: n=m, r <- M.abs_fun n n; assert_eq r (@id _))%MC.
Qed.

(* Abstracting a name with an index depending on it does not work if the (type of the)
   return value depends on it *)
Goal forall n m:nat, True.
  intros n m.
  mrun (mtry
          \nu H: n=m, r <- M.abs_fun (P:=fun n'=>n'=m) n H; M.ret I
        with AbsDependencyError => M.ret I end)%MC.
Qed.

(* No dependency in the term should raise no problem *)
Goal True.
  mrun (\nu x:nat, r <- M.abs_fun (P:=fun _ :nat=>nat) x 0; assert_eq r (fun _=>0))%MC.
Qed.

(* Abstracting a term depending on the return element is fine (the other way around is the problem) *)
Goal forall x, x>0 -> True.
  intros x H.
  mrun (r <- M.abs_fun (P:=fun _:x >0=>nat) H x; assert_eq r (fun _=>x))%MC.
Qed.

(* Evars prevent abstracting of a var *)
Goal forall A (x : A), True.
  intros A x.
  mrun (mtry e <- M.evar True; r <- M.abs_fun A e; M.ret e with AbsDependencyError => M.ret I end)%MC.
Qed.
