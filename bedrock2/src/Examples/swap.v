Require Import bedrock2.BasicC64Syntax bedrock2.NotationsInConstr.

Import Syntax BinInt String List.ListNotations.
Local Open Scope string_scope. Local Open Scope Z_scope. Local Open Scope list_scope.
Local Existing Instance bedrock2.BasicC64Syntax.StringNames_params.
Local Coercion var (x : string) : Syntax.expr := Syntax.expr.var x.

Definition swap := ("swap", (["a";"b"], ([]:list varname), bedrock_func_body:(
  "t" = *(uintptr_t*) "b";;
  *(uintptr_t*) "b" = *(uintptr_t*) "a";;
  *(uintptr_t*) "a" = "t"
))).

Definition swap_swap := ("swap_swap", (("a"::"b"::nil), ([]:list varname), bedrock_func_body:(
  Syntax.cmd.call [] "swap" [var "a"; var "b"];;
  Syntax.cmd.call [] "swap" [var "a"; var "b"]
))).

Require bedrock2.WeakestPrecondition.
Require Import bedrock2.Semantics bedrock2.BasicC64Semantics.
Require Import coqutil.Map.Interface bedrock2.Map.Separation bedrock2.Map.SeparationLogic.

Axiom __map_ok : map.ok Semantics.mem. Local Existing Instance __map_ok. (* FIXME *)

Require bedrock2.WeakestPreconditionProperties.
From coqutil.Tactics Require Import letexists eabstract.
Require Import bedrock2.ProgramLogic bedrock2.Scalars.

Local Infix "*" := sep.
Local Infix "*" := sep : type_scope.
Instance spec_of_swap : spec_of "swap" := fun functions =>
  forall a_addr a b_addr b m R t,
    (scalar access_size.word a_addr a * (scalar access_size.word b_addr b * R)) m ->
    WeakestPrecondition.call (fun _ => True) (fun _ => False) (fun _ _ => True) functions
      "swap" t m [a_addr; b_addr]
      (fun t' m' rets => t=t'/\ (scalar access_size.word a_addr b * (scalar access_size.word b_addr a * R)) m' /\ rets = nil).

Instance spec_of_swap_swap : spec_of "swap_swap" := fun functions =>
  forall a_addr a b_addr b m R t,
    (scalar access_size.word a_addr a * (scalar access_size.word b_addr b * R)) m ->
    WeakestPrecondition.call (fun _ => True) (fun _ => False) (fun _ _ => True) functions
      "swap_swap" t m [a_addr; b_addr]
      (fun t' m' rets => t=t' /\ (scalar access_size.word a_addr a * (scalar access_size.word b_addr b * R)) m' /\ rets = nil).

Lemma swap_ok : program_logic_goal_for_function! swap.
Proof.
  bind_body_of_function swap; cbv [spec_of spec_of_swap].
  intros.
  letexists. split. exact eq_refl. (* argument initialization *)

  repeat straightline.
  eapply Scalars.store_sep; [solve[SeparationLogic.ecancel_assumption]|].
  repeat straightline.
  eapply Scalars.store_sep; [solve[SeparationLogic.ecancel_assumption]|].
  repeat straightline.

  (* final postcondition *)
  split. exact eq_refl.
  split. 2:exact eq_refl.
  SeparationLogic.ecancel_assumption.
Defined.

Lemma swap_swap_ok : program_logic_goal_for_function! swap_swap.
Proof.
  bind_body_of_function swap_swap; cbv [spec_of_swap_swap].
  intros.
  letexists. split. exact eq_refl. (* argument initialization *)

  repeat straightline.
  straightline_call; [solve[SeparationLogic.ecancel_assumption]|].
  repeat straightline.
  letexists; split.
  { exact eq_refl. }

  repeat straightline.
  straightline_call; [solve[SeparationLogic.ecancel_assumption]|].
  repeat straightline.
  letexists; split.
  { exact eq_refl. }

  repeat straightline.
  repeat split; assumption.
Defined.

Lemma link_swap_swap_swap_swap : spec_of_swap_swap (swap_swap::swap::nil).
Proof. auto using swap_swap_ok, swap_ok. Qed.

Print Assumptions link_swap_swap_swap_swap.
(* __map_ok SortedListString.string_strict_order SortedList.sorted_remove SortedList.sorted_put StrictOrderWord *)