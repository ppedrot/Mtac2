(* Need to load Unicoq to get the module dependency right *)
Declare ML Module "unicoq".
(** Load library "MetaCoqPlugin.cma". *)
Declare ML Module "MetaCoqPlugin".

Require Import Strings.String.
Require Import NArith.BinNat.
Require Import NArith.BinNatDef.

From MetaCoq Require Export Types.

(* Set Universe Polymorphism. *)
Unset Universe Minimization ToSet.

Module MetaCoq.

Inductive Exception : Type := exception : Exception.

Definition NullPointer : Exception. exact exception. Qed.

Definition TermNotGround : Exception. exact exception. Qed.

Definition ArrayOutOfBounds : Exception. exact exception. Qed.

Definition NoPatternMatches : Exception. exact exception. Qed.

Definition WrongTerm : Exception. exact exception. Qed.

Definition MissingDependency : Exception. exact exception. Qed.

Definition LtacError (s:string) : Exception. exact exception. Qed.

Definition NotUnifiable {A} (x y : A) : Exception. exact exception. Qed.

Definition Failure (s : string) : Exception. exact exception. Qed.


Polymorphic Record dyn := Dyn { type : Type; elem :> type }.
Arguments Dyn {_} _.

Definition index := N.

Inductive array (A:Type) : Type :=
| carray : index -> N -> array A.

Inductive RedFlags : Set := RedBeta | RedDelta | RedIota | RedZeta.

Inductive Reduction : Set :=
| RedNone
| RedSimpl
| RedOneStep
| RedWhd : list RedFlags -> Reduction
| RedStrong : list RedFlags -> Reduction.

Notation RedNF := (RedStrong [RedBeta;RedDelta;RedZeta;RedIota]).
Notation RedHNF := (RedWhd [RedBeta;RedDelta;RedZeta;RedIota]).

Inductive Unification : Type :=
| UniCoq : Unification
| UniMatch : Unification
| UniMatchNoRed : Unification
| UniEvarconv : Unification.

Inductive Hyp : Type :=
| ahyp : forall {A}, A -> option A -> Hyp.

Inductive Hyps : Type :=
| hlocal : Hyps
| hminus : Hyps -> Hyps -> Hyps
| hhyps : list Hyp -> Hyps.

Record Case :=
    mkCase {
        case_ind : Type;
        case_val : case_ind;
        case_type : Type;
        case_return : dyn;
        case_branches : list dyn
        }.

(* Reduction primitive *)
Definition reduce (r : Reduction) {A} (x : A) := x.

(** Pattern matching without pain *)
Inductive pattern (M : Type->Prop) A (B : A -> Type) (t : A) : Prop :=
| pbase : forall (x:A), (t = x -> M (B x)) -> Unification -> pattern M A B t
| ptele : forall {C}, (forall (x : C), pattern M A B t) -> pattern M A B t.

(** goal type *)
Inductive goal :=
| TheGoal : forall {A}, A -> goal
| AHyp : forall {A}, option A -> (A -> goal) -> goal.

(** THE definition of MetaCoq *)
Set Printing Universes.
Unset Printing Notations.

Inductive MetaCoq
           : Type -> Prop :=
| tret : forall {A : Type}, A -> MetaCoq A
| bind : forall {A : Type} {B : Type},
    MetaCoq A -> (A -> MetaCoq B) -> MetaCoq B
| ttry : forall {A : Type}, MetaCoq A -> (Exception -> MetaCoq A) -> MetaCoq A
| raise : forall {A : Type}, Exception -> MetaCoq A
| tfix1' : forall {A : Type} {B : A -> Type} (S : Type -> Prop),
  (forall a : Type, S a -> MetaCoq a) ->
  ((forall x : A, S (B x)) -> (forall x : A, S (B x))) ->
  forall x : A, MetaCoq (B x)
| tfix2' : forall {A1 : Type} {A2 : A1 -> Type} {B : forall (a1 : A1), A2 a1 -> Type} (S : Type -> Prop),
  (forall a : Type, S a -> MetaCoq a) ->
  ((forall (x1 : A1) (x2 : A2 x1), S (B x1 x2)) ->
    (forall (x1 : A1) (x2 : A2 x1), S (B x1 x2))) ->
  forall (x1 : A1) (x2 : A2 x1), MetaCoq (B x1 x2)
| tfix3' : forall {A1 : Type} {A2 : A1 -> Type}  {A3 : forall (a1 : A1), A2 a1 -> Type} {B : forall (a1 : A1) (a2 : A2 a1), A3 a1 a2 -> Type} (S : Type -> Prop),
  (forall a : Type, S a -> MetaCoq a) ->
  ((forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2), S (B x1 x2 x3)) ->
    (forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2), S (B x1 x2 x3))) ->
  forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2), MetaCoq (B x1 x2 x3)
| tfix4' : forall {A1 : Type} {A2 : A1 -> Type} {A3 : forall (a1 : A1), A2 a1 -> Type} {A4 : forall (a1 : A1) (a2 : A2 a1), A3 a1 a2 -> Type} {B : forall (a1 : A1) (a2 : A2 a1) (a3 : A3 a1 a2), A4 a1 a2 a3 -> Type} (S : Type -> Prop),
  (forall a : Type, S a -> MetaCoq a) ->
  ((forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3), S (B x1 x2 x3 x4)) ->
    (forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3), S (B x1 x2 x3 x4))) ->
  forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3), MetaCoq (B x1 x2 x3 x4)
| tfix5' : forall {A1 : Type} {A2 : A1 -> Type} {A3 : forall (a1 : A1), A2 a1 -> Type} {A4 : forall (a1 : A1) (a2 : A2 a1), A3 a1 a2 -> Type} {A5 : forall (a1 : A1) (a2 : A2 a1) (a3 : A3 a1 a2), A4 a1 a2 a3 -> Type} {B : forall (a1 : A1) (a2 : A2 a1) (a3 : A3 a1 a2) (a4 : A4 a1 a2 a3), A5 a1 a2 a3 a4 -> Type} (S : Type -> Prop),
  (forall a : Type, S a -> MetaCoq a) ->
  ((forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3) (x5 : A5 x1 x2 x3 x4), S (B x1 x2 x3 x4 x5)) ->
    (forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3) (x5 : A5 x1 x2 x3 x4), S (B x1 x2 x3 x4 x5))) ->
  forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3) (x5 : A5 x1 x2 x3 x4), MetaCoq (B x1 x2 x3 x4 x5)

| is_var : forall {A : Type}, A -> MetaCoq bool
(* if the 4th argument is Some t, it adds x:=t to the local context *)
| tnu : forall {A : Type} {B : Type}, string -> option A -> (A -> MetaCoq B) -> MetaCoq B
| abs : forall {A : Type} {P : A -> Type} (x : A), P x -> MetaCoq (forall x, P x)
| abs_let : forall {A : Type} {P : A -> Type} (x: A) (t: A), P x -> MetaCoq (let x := t in P x)
| abs_prod : forall {A : Type} {P : A -> Type} (x : A), P x -> MetaCoq Type
(** [abs_fix f t n] creates a fixpoint with variable [f] as name, *)
(*     with body t, *)
(*     and reducing the n-th product of [f]. This means that [f]'s type *)
(*     is expected to be of the form [forall x1, ..., xn, T] *)
| abs_fix : forall {A : Type}, A -> A -> N -> MetaCoq A

(* [get_binder_name t] returns the name of variable [x] if: *)
(*    - [t = x], *)
(*    - [t = forall x, P x], *)
(*    - [t = fun x=>b], *)
(*    - [t = let x := d in b]. *)
(* *)
| get_binder_name : forall {A : Type}, A -> MetaCoq string
| remove : forall {A : Type} {B : Type}, A -> MetaCoq B -> MetaCoq B

| evar : forall (A : Type), MetaCoq A
| Cevar : forall (A : Type), list Hyp -> MetaCoq A
| is_evar : forall {A : Type}, A -> MetaCoq bool

| hash : forall {A : Type}, A -> N -> MetaCoq N
| solve_typeclasses : MetaCoq unit

| array_make : forall {A : Type}, N -> A -> MetaCoq (array A)
| array_get : forall {A : Type}, array A -> N -> MetaCoq A
| array_set : forall {A : Type}, array A -> N -> A -> MetaCoq unit

| print : string -> MetaCoq unit
| pretty_print : forall {A : Type}, A -> MetaCoq string

| hypotheses : MetaCoq (list Hyp)

| destcase : forall {A : Type} (a : A), MetaCoq (Case)

(** Given an inductive type A, applied to all its parameters (but not *)
(*     necessarily indices), it returns the type applied to exactly the *)
(*     parameters, and a list of constructors (applied to the parameters). *)
| constrs : forall {A : Type} (a : A), MetaCoq (prod dyn (list dyn))
| makecase : forall (C : Case), MetaCoq dyn

(** [munify x y r] uses reduction strategy [r] to equate [x] and [y].
    It uses convertibility of universes. *)
| munify {A} (x y : A) : Unification -> MetaCoq (option (x = y))

| call_ltac : forall {A : Type}, string -> list dyn -> MetaCoq (prod A (list goal))
| list_ltac : MetaCoq unit

| match_and_run : forall {A : Type} {B : A -> Type} {t}, pattern MetaCoq A B t -> MetaCoq (option (B t))

(** [munify_cumul x y r] uses reduction strategy [r] to equate [x] and [y].
    Note that they might have different types.
    It uses cumulativity of universes, e.g., it succeeds if [x] is [Prop] and [y] is [Type]. *)
| munify_cumul {A B} (x: A) (y: B) : Unification -> MetaCoq bool
.
(* Inductive MetaCoq *)
(*           @{ mc_max *)
(* mc_tret *)
(* mc_tbindA *)
(* mc_tbindB *)
(* mc_ttry *)
(* mc_ttry_exc *)
(* mc_raise *)
(* mc_raise_exc *)
(* mc_tfix1_A *)
(* mc_tfix1_B *)
(* mc_tfix1_S *)
(* mc_tfix1_a *)
(* mc_tfix2_A1 *)
(* mc_tfix2_A2 *)
(* mc_tfix2_B *)
(* mc_tfix2_S *)
(* mc_tfix2_a *)
(* mc_tfix3_A1 *)
(* mc_tfix3_A2 *)
(* mc_tfix3_A3 *)
(* mc_tfix3_B *)
(* mc_tfix3_S *)
(* mc_tfix3_a *)
(* mc_tfix4_A1 *)
(* mc_tfix4_A2 *)
(* mc_tfix4_A3 *)
(* mc_tfix4_A4 *)
(* mc_tfix4_B *)
(* mc_tfix4_S *)
(* mc_tfix4_a *)
(* mc_tfix5_A1 *)
(* mc_tfix5_A2 *)
(* mc_tfix5_A3 *)
(* mc_tfix5_A4 *)
(* mc_tfix5_A5 *)
(* mc_tfix5_B *)
(* mc_tfix5_S *)
(* mc_tfix5_a *)
(* mc_is_var_A *)
(* mc_tnu_A *)
(* mc_tnu_B *)
(* mc_tnu_opt *)
(* mc_abs_A *)
(* mc_abs_P *)
(* mc_abs_let_A *)
(* mc_abs_let_P *)
(* mc_abs_prod_A *)
(* mc_abs_prod_P *)
(* mc_abs_result *)
(* mc_abs_fix_A *)
(* mc_get_binder_name_A *)
(* mc_remove_A *)
(* mc_remove_B *)
(* mc_evar_A *)
(* mc_Cevar_A *)
(* mc_Cevar_list *)
(* mc_Cevar_Hyp *)
(* mc_is_evar_A *)
(* mc_hash_A *)
(* mc_array_make_A *)
(* mc_array_get_A *)
(* mc_array_set_A *)
(* mc_array_make_array *)
(* mc_array_get_array *)
(* mc_array_set_array *)
(* mc_pretty_print_A *)
(* mc_makecase_dyn *)
(* mc_destcase_A *)
(* mc_constrs_A *)
(* mc_constrs_prod1 mc_constrs_prod2 *)
(* mc_munify_A *)
(* mc_munify_eq1 mc_munify_eq_2 *)
(* mc_munify_opt *)
(* mc_call_ltac_A *)
(* mc_match_and_run_A *)
(* mc_match_and_run_B *)
(* mc_match_and_run_pat1 mc_match_and_run_pat2 mc_match_and_run_pat3 mc_match_and_run_pat4 mc_match_and_run_pat5 *)
(* mc_match_and_run_opt *)
(* mc_hypotheses_list *)
(* mc_hypotheses_Hyp *)
(* mc_call_ltac_list_dyn *)
(* mc_call_ltac_dyn *)
(* mc_call_ltac_list_result *)
(* mc_constrs_dyn1 *)
(* mc_constrs_dyn2 *)
(* mc_constrs_list *)
(* mc_call_ltac_goal1 mc_call_ltac_goal2 *)
(* mc_destcase_case1 mc_destcase_case2 mc_destcase_case3 mc_destcase_cas4 mc_destcase_case5 *)
(* mc_makecase_case1 mc_makecase_case2 mc_makecase_case3 mc_makecase_cas4 mc_makecase_case5 *)
(* mc_call_ltac_prod1 mc_call_ltac_prod2 *)
(*           } : Type@{mc_max} -> Prop := *)
(* | tret : forall {A : Type@{mc_tret}}, A -> MetaCoq A *)
(* | bind : forall {A : Type@{mc_tbindA}} {B : Type@{mc_tbindB}}, *)
(*     MetaCoq A -> (A -> MetaCoq B) -> MetaCoq B *)
(* | ttry : forall {A : Type@{mc_ttry}}, MetaCoq A -> (Exception@{mc_ttry_exc} -> MetaCoq A) -> MetaCoq A *)
(* | raise : forall {A : Type@{mc_raise}}, Exception@{mc_raise_exc} -> MetaCoq A *)
(* | tfix1' : forall {A : Type@{mc_tfix1_A}} {B : A -> Type@{mc_tfix1_B}} (S : Type@{mc_tfix1_S} -> Prop), *)
(*   (forall a : Type@{mc_tfix1_a}, S a -> MetaCoq a) -> *)
(*   ((forall x : A, S (B x)) -> (forall x : A, S (B x))) -> *)
(*   forall x : A, MetaCoq (B x) *)
(* | tfix2' : forall {A1 : Type@{mc_tfix2_A1}} {A2 : A1 -> Type@{mc_tfix2_A2}} {B : forall (a1 : A1), A2 a1 -> Type@{mc_tfix2_B}} (S : Type@{mc_tfix2_S} -> Prop), *)
(*   (forall a : Type@{mc_tfix2_a}, S a -> MetaCoq a) -> *)
(*   ((forall (x1 : A1) (x2 : A2 x1), S (B x1 x2)) -> *)
(*     (forall (x1 : A1) (x2 : A2 x1), S (B x1 x2))) -> *)
(*   forall (x1 : A1) (x2 : A2 x1), MetaCoq (B x1 x2) *)
(* | tfix3' : forall {A1 : Type@{mc_tfix3_A1}} {A2 : A1 -> Type@{mc_tfix3_A2}}  {A3 : forall (a1 : A1), A2 a1 -> Type@{mc_tfix3_A3}} {B : forall (a1 : A1) (a2 : A2 a1), A3 a1 a2 -> Type@{mc_tfix3_B}} (S : Type@{mc_tfix3_S} -> Prop), *)
(*   (forall a : Type@{mc_tfix3_a}, S a -> MetaCoq a) -> *)
(*   ((forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2), S (B x1 x2 x3)) -> *)
(*     (forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2), S (B x1 x2 x3))) -> *)
(*   forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2), MetaCoq (B x1 x2 x3) *)
(* | tfix4' : forall {A1 : Type@{mc_tfix4_A1}} {A2 : A1 -> Type@{mc_tfix4_A2}} {A3 : forall (a1 : A1), A2 a1 -> Type@{mc_tfix4_A3}} {A4 : forall (a1 : A1) (a2 : A2 a1), A3 a1 a2 -> Type@{mc_tfix4_A4}} {B : forall (a1 : A1) (a2 : A2 a1) (a3 : A3 a1 a2), A4 a1 a2 a3 -> Type@{mc_tfix4_B}} (S : Type@{mc_tfix4_S} -> Prop), *)
(*   (forall a : Type@{mc_tfix4_a}, S a -> MetaCoq a) -> *)
(*   ((forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3), S (B x1 x2 x3 x4)) -> *)
(*     (forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3), S (B x1 x2 x3 x4))) -> *)
(*   forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3), MetaCoq (B x1 x2 x3 x4) *)
(* | tfix5' : forall {A1 : Type@{mc_tfix5_A1}} {A2 : A1 -> Type@{mc_tfix5_A2}} {A3 : forall (a1 : A1), A2 a1 -> Type@{mc_tfix5_A3}} {A4 : forall (a1 : A1) (a2 : A2 a1), A3 a1 a2 -> Type@{mc_tfix5_A4}} {A5 : forall (a1 : A1) (a2 : A2 a1) (a3 : A3 a1 a2), A4 a1 a2 a3 -> Type@{mc_tfix5_A5}} {B : forall (a1 : A1) (a2 : A2 a1) (a3 : A3 a1 a2) (a4 : A4 a1 a2 a3), A5 a1 a2 a3 a4 -> Type@{mc_tfix5_B}} (S : Type@{mc_tfix5_S} -> Prop), *)
(*   (forall a : Type@{mc_tfix5_a}, S a -> MetaCoq a) -> *)
(*   ((forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3) (x5 : A5 x1 x2 x3 x4), S (B x1 x2 x3 x4 x5)) -> *)
(*     (forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3) (x5 : A5 x1 x2 x3 x4), S (B x1 x2 x3 x4 x5))) -> *)
(*   forall (x1 : A1) (x2 : A2 x1) (x3 : A3 x1 x2) (x4 : A4 x1 x2 x3) (x5 : A5 x1 x2 x3 x4), MetaCoq (B x1 x2 x3 x4 x5) *)

(* | is_var : forall {A : Type@{mc_is_var_A}}, A -> MetaCoq bool *)
(* (* if the 4th argument is Some t, it adds x:=t to the local context *) *)
(* | tnu : forall {A : Type@{mc_tnu_A}} {B : Type@{mc_tnu_B}}, string -> option@{mc_tnu_opt} A -> (A -> MetaCoq B) -> MetaCoq B *)
(* | abs : forall {A : Type@{mc_abs_A}} {P : A -> Type@{mc_abs_P}} (x : A), P x -> MetaCoq (forall x, P x) *)
(* | abs_let : forall {A : Type@{mc_abs_let_A}} {P : A -> Type@{mc_abs_let_P}} (x: A) (t: A), P x -> MetaCoq (let x := t in P x) *)
(* | abs_prod : forall {A : Type@{mc_abs_prod_A}} {P : A -> Type@{mc_abs_prod_P}} (x : A), P x -> MetaCoq Type@{mc_abs_result} *)
(* (** [abs_fix f t n] creates a fixpoint with variable [f] as name, *) *)
(* (*     with body t, *) *)
(* (*     and reducing the n-th product of [f]. This means that [f]'s type *) *)
(* (*     is expected to be of the form [forall x1, ..., xn, T] *) *)
(* | abs_fix : forall {A : Type@{mc_abs_fix_A}}, A -> A -> N -> MetaCoq A *)

(* (* [get_binder_name t] returns the name of variable [x] if: *)
(*    - [t = x], *)
(*    - [t = forall x, P x], *)
(*    - [t = fun x=>b], *)
(*    - [t = let x := d in b]. *)
(* *) *)
(* | get_binder_name : forall {A : Type@{mc_get_binder_name_A}}, A -> MetaCoq string *)
(* | remove : forall {A : Type@{mc_remove_A}} {B : Type@{mc_remove_B}}, A -> MetaCoq B -> MetaCoq B *)

(* | evar : forall {A : Type@{mc_evar_A}}, MetaCoq A *)
(* | Cevar : forall {A : Type@{mc_Cevar_A}}, list@{mc_Cevar_list} Hyp@{mc_Cevar_Hyp} -> MetaCoq A *)
(* | is_evar : forall {A : Type@{mc_is_evar_A}}, A -> MetaCoq bool *)

(* | hash : forall {A : Type@{mc_hash_A}}, A -> N -> MetaCoq N *)
(* | solve_typeclasses : MetaCoq unit *)

(* | array_make : forall {A : Type@{mc_array_make_A}}, N -> A -> MetaCoq (array@{mc_array_make_array} A) *)
(* | array_get : forall {A : Type@{mc_array_get_A}}, array@{mc_array_get_array} A -> N -> MetaCoq A *)
(* | array_set : forall {A : Type@{mc_array_set_A}}, array@{mc_array_set_array} A -> N -> A -> MetaCoq unit *)

(* | print : string -> MetaCoq unit *)
(* | pretty_print : forall {A : Type@{mc_pretty_print_A}}, A -> MetaCoq string *)

(* | hypotheses : MetaCoq (list@{mc_hypotheses_list} Hyp@{mc_hypotheses_Hyp}) *)

(* | destcase : forall {A : Type@{mc_destcase_A}} (a : A), MetaCoq (Case@{mc_destcase_case1 mc_destcase_case2 mc_destcase_case3 mc_destcase_cas4 mc_destcase_case5}) *)

(* (** Given an inductive type A, applied to all its parameters (but not *)
(*     necessarily indices), it returns the type applied to exactly the *)
(*     parameters, and a list of constructors (applied to the parameters). *) *)
(* | constrs : forall {A : Type@{mc_constrs_A}} (a : A), MetaCoq (prod@{mc_constrs_prod1 mc_constrs_prod2} dyn@{mc_constrs_dyn1} (list@{mc_constrs_list} dyn@{mc_constrs_dyn2})) *)
(* | makecase : forall (C : Case@{mc_makecase_case1 mc_makecase_case2 mc_makecase_case3 mc_makecase_cas4 mc_makecase_case5}), MetaCoq dyn@{mc_makecase_dyn} *)

(* | munify {A : Type@{mc_munify_A}} (x y : A) : Unification -> MetaCoq (option@{mc_munify_opt} (eq@{mc_munify_eq1 mc_munify_eq_2} x y)) *)

(* | call_ltac : forall {A : Type@{mc_call_ltac_A}}, string -> list@{mc_call_ltac_list_dyn} dyn@{mc_call_ltac_dyn} -> MetaCoq (prod@{mc_call_ltac_prod1 mc_call_ltac_prod2} A (list@{mc_call_ltac_list_result} goal@{mc_call_ltac_goal1 mc_call_ltac_goal2})) *)
(* | list_ltac : MetaCoq unit *)

(* | match_and_run : forall {A : Type@{mc_match_and_run_A}} {B : A -> Type@{mc_match_and_run_B}} {t}, pattern@{mc_match_and_run_pat1 mc_match_and_run_pat2 mc_match_and_run_pat3 mc_match_and_run_pat4 mc_match_and_run_pat5} MetaCoq A B t -> MetaCoq (option@{mc_match_and_run_opt} (B t)) *)
(* . *)

Definition failwith {A} s : MetaCoq A := raise (Failure s).

Definition array_length : forall {A}, array A -> N :=
  fun A m => match m with carray _ _ l => l end.


Definition tfix1 {A} B := @tfix1' A B MetaCoq (fun _ x => x).
Definition tfix2 {A1 A2} B := @tfix2' A1 A2 B MetaCoq (fun _ x => x).
Definition tfix3 {A1 A2 A3} B := @tfix3' A1 A2 A3 B MetaCoq (fun _ x => x).
Definition tfix4 {A1 A2 A3 A4} B := @tfix4' A1 A2 A3 A4 B MetaCoq (fun _ x => x).
Definition tfix5 {A1 A2 A3 A4 A5} B := @tfix5' A1 A2 A3 A4 A5 B MetaCoq (fun _ x => x).

Definition Ref := array.

Definition ref : forall {A}, A -> MetaCoq (Ref A) :=
  fun A x=> array_make 1%N x.

Definition read : forall {A}, Ref A -> MetaCoq A :=
  fun A r=> array_get r 0%N.

Definition write : forall {A}, Ref A -> A -> MetaCoq unit :=
  fun A r c=> array_set r 0%N c.

(** Defines [eval f] to execute after elaboration the Mtactic [f].
    It allows e.g. [rewrite (eval f)]. *)
Class runner A  (f : MetaCoq A) := { eval : A }.
Arguments runner {A} _.
Arguments Build_runner {A} _ _.
Arguments eval {A} _ {_}.

Hint Extern 20 (runner ?f) =>
  (exact (Build_runner f ltac:(mrun f)))  : typeclass_instances.



Definition print_term {A} (x : A) : MetaCoq unit :=
  bind (pretty_print x) (fun s=> print s).

End MetaCoq.

Export MetaCoq.


Module MetaCoqNotations.

Notation "'M'" := MetaCoq.

Notation "'simpl'" := (reduce RedSimpl).
Notation "'hnf'" := (reduce RedHNF).
Notation "'one_step'" := (reduce RedOneStep).

Notation "'ret'" := (tret).
Notation "'retS' e" := (let s := simpl e in ret s) (at level 20).

Notation "r '<-' t1 ';' t2" := (@bind _ _ t1 (fun r=> t2))
  (at level 81, right associativity).
Notation "t1 ';;' t2" := (@bind _ _ t1 (fun _=>t2))
  (at level 81, right associativity).
Notation "f @@ x" := (bind f (fun r=>ret (r x))) (at level 70).
Notation "f >> x" := (bind f (fun r=>x r)) (at level 70).
Open Scope string.

(* We cannot make this notation recursive, so we loose
   notation in favor of naming. *)
Notation "'nu' x , a" := (
  let f := fun x=>a in
  n <- get_binder_name f;
  tnu n None f) (at level 81, x at next level, right associativity).

Notation "'nu' x : A , a" := (
  let f := fun x:A=>a in
  n <- get_binder_name f;
  tnu n None f) (at level 81, x at next level, right associativity).

Notation "'nu' x := t , a" := (
  let f := fun x=>a in
  n <- get_binder_name f;
  tnu n (Some t) f) (at level 81, x at next level, right associativity).

Notation "'mfix1' f ( x : A ) : 'M' T := b" := (tfix1 (fun x=>T) (fun f (x : A)=>b))
  (at level 85, f at level 0, x at next level, format
  "'[v  ' 'mfix1'  f  '(' x  ':'  A ')'  ':'  'M'  T  ':=' '/  ' b ']'").

Notation "'mfix2' f ( x : A ) ( y : B ) : 'M' T := b" :=
  (tfix2 (fun (x : A) (y : B)=>T) (fun f (x : A) (y : B)=>b))
  (at level 85, f at level 0, x at next level, y at next level, format
  "'[v  ' 'mfix2'  f  '(' x  ':'  A ')'  '(' y  ':'  B ')'  ':'  'M'   T  ':=' '/  ' b ']'").

Notation "'mfix3' f ( x : A ) ( y : B ) ( z : C ) : 'M' T := b" :=
  (tfix3 (fun (x : A) (y : B) (z : C)=>T) (fun f (x : A) (y : B) (z : C)=>b))
  (at level 85, f at level 0, x at next level, y at next level, z at next level, format
  "'[v  ' 'mfix3'  f  '(' x  ':'  A ')'  '(' y  ':'  B ')'  '(' z  ':'  C ')'  ':'  'M'  T  ':=' '/  ' b ']'").

Notation "'mfix4' f ( x1 : A1 ) ( x2 : A2 ) ( x3 : A3 ) ( x4 : A4 ) : 'M' T := b" :=
  (tfix4 (fun (x1 : A1) (x2 : A2) (x3 : A3) (x4 : A4)=>T) (fun f (x1 : A1) (x2 : A2) (x3 : A3) (x4 : A4) =>b))
  (at level 85, f at level 0, x1 at next level, x2 at next level, x3 at next level, x4 at next level, format
  "'[v  ' 'mfix4'  f  '(' x1  ':'  A1 ')'  '(' x2  ':'  A2 ')'  '(' x3  ':'  A3 ')'  '(' x4  ':'  A4 ')'  ':'  'M'  T  ':=' '/  ' b ']'").

Notation "'mfix5' f ( x1 : A1 ) ( x2 : A2 ) ( x3 : A3 ) ( x4 : A4 ) ( x5 : A5 ) : 'M' T := b" :=
  (tfix5 (fun (x1 : A1) (x2 : A2) (x3 : A3) (x4 : A4) (x5 : A5)=>T) (fun f (x1 : A1) (x2 : A2) (x3 : A3) (x4 : A4) (x5 : A5) =>b))
  (at level 85, f at level 0, x1 at next level, x2 at next level, x3 at next level, x4 at next level, x5 at next level, format
  "'[v  ' 'mfix5'  f  '(' x1  ':'  A1 ')'  '(' x2  ':'  A2 ')'  '(' x3  ':'  A3 ')'  '(' x4  ':'  A4 ')'  '(' x5  ':'  A5 ')'  ':'  'M'  T  ':=' '/  ' b ']'").


Definition type_inside {A} (x : M A) := A.


Definition NoPatternMatches : Exception. exact exception. Qed.
Definition Anomaly : Exception. exact exception. Qed.
Definition Continue : Exception. exact exception. Qed.

Notation pattern := (pattern MetaCoq).

Fixpoint tmatch {A P} t (ps : list (pattern A P t)) : M (P t) :=
  match ps with
  | [] => raise NoPatternMatches
  | (p :: ps') =>
    v <- match_and_run p;
    match v with
    | None => tmatch t ps'
    | Some v => ret v
    end
  end.

Arguments ptele {_ A B t C} _.
Arguments pbase {_ A B t} _ _ _.


Notation "[? x .. y ] ps" := (ptele (fun x=> .. (ptele (fun y=>ps)).. ))
  (at level 202, x binder, y binder, ps at next level) : metaCoq_pattern_scope.
Notation "p => b" := (pbase p%core (fun _=>b%core) UniMatch)
  (no associativity, at level 201) : metaCoq_pattern_scope.
Notation "p => [ H ] b" := (pbase p%core (fun H=>b%core) UniMatch)
  (no associativity, at level 201, H at next level) : metaCoq_pattern_scope.
Notation "'_' => b " := (ptele (fun x=> pbase x (fun _=>b%core) UniMatch))
  (at level 201, b at next level) : metaCoq_pattern_scope.

Notation "p '=n>' b" := (pbase p%core (fun _=>b%core) UniMatchNoRed)
  (no associativity, at level 201) : metaCoq_pattern_scope.
Notation "p '=n>' [ H ] b" := (pbase p%core (fun H=>b%core) UniMatchNoRed)
  (no associativity, at level 201, H at next level) : metaCoq_pattern_scope.

Delimit Scope metaCoq_pattern_scope with metaCoq_pattern.

Notation "'with' | p1 | .. | pn 'end'" :=
  ((cons p1%metaCoq_pattern (.. (cons pn%metaCoq_pattern nil) ..)))
    (at level 91, p1 at level 210, pn at level 210).
Notation "'with' p1 | .. | pn 'end'" :=
  ((cons p1%metaCoq_pattern (.. (cons pn%metaCoq_pattern nil) ..)))
    (at level 91, p1 at level 210, pn at level 210).

Notation "'mmatch' x ls" := (@tmatch _ (fun _=>_) x ls)
  (at level 90, ls at level 91).
Notation "'mmatch' x 'return' 'M' p ls" := (@tmatch _ (fun x=>p) x ls)
  (at level 90, ls at level 91).
Notation "'mmatch' x 'as' y 'return' 'M' p ls" := (@tmatch _ (fun y=>p) x ls)
  (at level 90, ls at level 91).


Notation "'mtry' a ls" :=
  (ttry a (fun e=>
    (@tmatch _ (fun _=>_) e (app ls (cons ([? x] x=>raise x)%metaCoq_pattern nil)))))
    (at level 82, a at level 100, ls at level 91, only parsing).

Notation "! a" := (read a) (at level 80).
Notation "a ::= b" := (write a b) (at level 80).

End MetaCoqNotations.


Module Array.
  Require Import Arith_base.

  Import MetaCoqNotations.

  Definition t A := array A.

  Definition make {A} n (c : A)  :=
    MetaCoq.array_make n c.

  Definition length {A} (a : t A) :=
    MetaCoq.array_length a.

  Definition get {A} (a : t A) i :=
    MetaCoq.array_get a i.

  Definition set {A} (a : t A) i (c : A) :=
    MetaCoq.array_set a i c.

  Definition iter {A} (a : t A) (f : N -> A -> M unit) : M unit :=
    let n := length a in
    N.iter n (fun i : M N =>
      i' <- i;
      e <- get a i';
      f i' e;;
      retS (N.succ i'))
      (ret 0%N);;
    ret tt.

  Definition No0LengthArray : Exception. exact exception. Qed.

  Definition init {A:Type} n (f : N -> M A) : M (t A) :=
    match n with
    | N0 => raise No0LengthArray
    | _ =>
      c <- f 0%N;
        a <- make n c;
        N.iter (N.pred n) (fun i : M N =>
            i' <- i;
            e <- f i';
            set a i' e;;
            retS (N.succ i'))
          (ret 1%N);;
        ret a
    end.

  (* Definition to_list {A} (a : t A) := *)
  (*   let n := length a in *)
  (*   r <- N.iter n (fun l : M (N * list A)%type => *)
  (*     l' <- l; *)
  (*     let (i, s) := l' in *)
  (*     e <- get a i; *)
  (*     retS (N.succ i, e :: s)) *)
  (*   (ret (0%N, nil)); *)
  (*   retS (snd r). *)

  Definition copy {A} (a b : t A) :=
    let n := length a in
    N.iter n (fun i : M N =>
      i' <- i;
      e <- get a i';
      set b i' e;;
      retS (N.succ i'))
      (ret 0%N).

End Array.
