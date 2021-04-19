(*|  
==============================
 The famous Ackermann function 
==============================

--------------------------------
   Definitions and properties
--------------------------------

|*)

From hydras Require Export Iterates Exp2.
From Coq Require Import Lia.
Require Import Coq.Program.Wf.
Require Import Coq.Arith.Arith.

(*| 

Various definitions
===================


A first try ...
---------------


The following definition fails, because Coq cannot guess a  decreasing argument.
|*)



Fail
  Fixpoint Ack (m n : nat) : nat :=
  match m, n with
  | 0, n => S n
  | S m, 0 => Ack m 1
  | S m0, S p => Ack m0 (Ack m p)
  end.



(*| 

Fortunately, there are still several ways to define the Ackermnn function in Coq. We present a few of them, using the module system to mask all these definitions but one.


Definition with inner fixpoint
------------------------------

|*)


Module Alt.
  
  Fixpoint Ack (m n : nat) : nat :=
    match m with
    | O => S n
    | S p => let fix Ackm (n : nat) :=
                 match n with
                 | O => Ack p 1
                 | S q => Ack p (Ackm q)
                 end
             in Ackm n
    end.

  Compute Ack 3 2.
  
End Alt.


(*| 

Definition using the ``iterate`` functional
--------------------------------------------

   ``iterate : forall {A : Type}, (A -> A) -> nat -> A -> A``


This definition allows  us to to prove monotony properties of ``Ack  m`` by induction on ``m`` (using lemmas from our library ``Prelude.Iterates``). 

|*)

Fixpoint Ack (m:nat) : nat -> nat :=
  match m with
  | 0 => S
  | S n => fun k =>  iterate (Ack n) (S k) 1
  end.

Compute Ack 3 2.


(*| 

Using the lexicographic ordering 
---------------------------------

   (post by Anton Trunov in stackoverflow (May 2018))
|*)

(*| .. coq:: none |*)

Definition lex_nat (ab1 ab2 : nat * nat) : Prop :=
  match ab1, ab2 with
  | (a1, b1), (a2, b2) => 
    (a1 < a2) \/ ((a1 = a2) /\ (b1 < b2))
  end.


(* This is defined in stdlib, but unfortunately it is opaque *)
Lemma lt_wf_ind :
  forall n (P:nat -> Prop),
    (forall n, (forall m, m < n -> P m) -> P n) ->
    P n.
Proof. intro p; intros; elim (lt_wf p); auto with arith. Defined.

(* This is defined in stdlib, but unfortunately it is opaque too *)



Lemma lt_wf_double_ind :
  forall P:nat -> nat -> Prop,
    (forall n m,
        (forall p (q:nat), p < n -> P p q) ->
        (forall p, p < m -> P n p) -> P n m) ->
    forall n m, P n m.
Proof.
  intros P Hrec p. pattern p. apply lt_wf_ind.
  intros n H q. pattern q. apply lt_wf_ind. auto.
Defined.

(*||*)

Lemma lex_nat_wf : well_founded lex_nat.
(*| .. coq:: none |*)
Proof.
  intros (a, b); pattern a, b; apply lt_wf_double_ind.
  intros m n H1 H2.
  constructor; intros (m', n') [G | [-> G]].
  - now apply H1.
  - now apply H2.
Defined.

(*|
   
Using Program Fixpoint
+++++++++++++++++++++++

|*)

Module Alt2.

  (* "Program" is not echoed *)
  
  Program Fixpoint Ack (ab : nat * nat) {wf lex_nat ab} : nat :=
    match ab with
    | (0, b) => b + 1
    | (S a, 0) => Ack (a, 1)
    | (S a, S b) => Ack (a, Ack (S a, b))
    end.
  Next Obligation.
    injection Heq_ab; intros; subst.
    left; auto with arith.
  Defined.
  Next Obligation.
    apply lex_nat_wf.
  Defined.
  
  Example test1 : Ack (1, 2) = 4 := refl_equal.  


  Example test2 : Ack (3, 4) = 125 := eq_refl.
  (* this may take several seconds *)
  
End Alt2.


(*|
Using the Equations plug-in 
++++++++++++++++++++++++++++

|*)


From Equations Require Import Equations. 

Instance Lex_nat_wf : WellFounded lex_nat.
apply lex_nat_wf.
Defined.



Module Alt3.

  Equations ack (p : nat * nat) : nat by wf p lex_nat :=
    ack (0, n) := S n ;
    ack (S m, 0) := ack (m, 1);
    ack (S m, S n) := ack (m, ack (S m, n)).


  Definition Ack (m n: nat): nat := ack (m,n).
  
End Alt3.



(*|

Exercise 


   Prove that the four definitions of the Ackermann function 
   [Ack] , [Alt.Ack], [Alt2.Ack],  and [Alt3.ack] are extensionnally equal 
 
|*)


(*| 
    
First levels of the ``Ack n`` hierarchy
----------------------------------------

Usual equations 
+++++++++++++++

|*)

Lemma Ack_0 : Ack 0 = S.
Proof refl_equal.

Lemma Ack_S_0 m : Ack (S m) 0 = Ack m 1. 
Proof.  now cbn. Qed.

Lemma Ack_S_S : forall m p,
    Ack (S m) (S p) = Ack m (Ack (S m) p).
Proof.  now cbn. Qed.

(*|

m=1,2,3 ...


|*)



Lemma Ack_1_n n : Ack 1 n = S (S n).
Proof.
  f_equal;induction n; cbn ;auto.
Qed.  

Lemma Ack_2_n n: Ack 2  n = 2 * n + 3.
Proof.
  induction  n.
  -  reflexivity. 
  -  rewrite Ack_S_S, IHn, Ack_1_n; lia.
Qed.


Lemma Ack_3_n n: Ack 3 n = exp2 (S (S (S n))) - 3.
Proof.
  induction n.
  (* ... *)(*| .. coq:: none *)
  -  reflexivity.
  - rewrite Ack_S_S, Ack_2_n, IHn.
    change (exp2 (S (S (S (S n)))))
      with (2 * exp2 (S (S (S n)))).
    assert (3 <= exp2 (S (S (S n)))).
    { clear IHn;induction n; cbn.
      - auto with arith.
      - cbn in IHn; lia.
    }
    lia.
    (*||*)
Qed.



Lemma Ack_4_n n : Ack 4 n = hyper_exp2 (S (S (S n))) - 3.
Proof.
  induction n.
  - reflexivity. 
  -  assert (3 <= hyper_exp2 (S (S (S n)))).
     {
       (* ... *) (*| .. coq:: none |*)
       clear IHn; induction n.
       - cbn;  auto with arith.
       - rewrite hyper_exp2_S; 
           transitivity (hyper_exp2 (S (S (S n)))); auto.
         generalize (hyper_exp2 (S (S (S n))));
           intro n0; induction  n0.
         + auto with arith.
         +  assert (0 < exp2 n0).
            { clear IHn0; induction n0.
              - cbn;auto.
              - cbn; lia.
            }
            cbn; lia.
      (*||*)
     }
     rewrite Ack_S_S, IHn.
     (* ... *)  (*| .. coq:: none |*)
     rewrite Ack_3_n; rewrite (hyper_exp2_S  (S (S (S n)))).
     replace (S (S (S (hyper_exp2 (S (S (S n))) - 3))))
       with (hyper_exp2 (S (S (S n)))); auto.
     lia.
     (*||*)
Qed.




(*|  

Monotony properties




|*)

Section Ack_Properties.
  
  Let P (m:nat) := strict_mono (Ack m) /\
                   S <<=  (Ack m) /\
                   (forall n,  Ack m n <= Ack (S m) n).

  (*| 
Base case 
  |*)
  

  Remark P0 : P 0.
  (*| .. coq:: none |*)
  Proof.
    repeat split.
    - intros x y; cbn; auto with arith.
    -  apply smono_Sle.
       + discriminate.
       + intros x y; cbn; auto with arith.
    - intro n; simpl (Ack 1); cbn; induction n; cbn; auto with arith. 
  Qed.
  (*||*)
  
  (*|

Induction step

|*)
  
  Section Induc_step.
    Variable m:nat.
    Hypothesis Hm : P m.

    (*|
A few lemmas ...

|*)

    
    Remark  Rem1 : strict_mono (Ack (S m)). (* .no-goals *)
    (*| .. coq:: none |*)
    Proof.
      intros n p H; cbn.
      destruct Hm as [H1 H2]; apply H1.
      apply iterate_lt; auto.
      destruct H2;  auto.
    Qed.
    (*||*)
    
    Remark Rem2 : S <<= Ack (S m). (* .no-goals *)
    (*| .. coq:: none |*)    
    Proof.
      intros p; destruct Hm as [H1 [H2 H3]];
        transitivity (Ack m p); auto.
    Qed.
    (*||*)


    Remark Ack_m_mono_weak n p :  n <= p ->
                                  Ack m n <= Ack m p. (* .no-goals *)
    (*| .. coq:: none |*)
    Proof.
      intros H; destruct (Lt.le_lt_or_eq _ _ H).
      apply PeanoNat.Nat.lt_le_incl; auto.
      - destruct Hm as [H1 _]; apply H1; auto.
      - subst p; auto.
    Qed.
    (*||*)
    
    Remark Rem3 : forall n, Ack (S m) n <= Ack (S (S m)) n. (* .no-goals *)
    (*| .. coq:: none |*)
    Proof.
      destruct Hm as [H1 [H2 H3]].
      intro n; simpl (Ack (S (S m)) n); simpl (Ack (S m) n).  
      apply Ack_m_mono_weak.
      apply iterate_le_np_le.
      - intro p; transitivity (S p); auto.
      - transitivity (S n); auto.
        replace (S n) with (iterate S n 1).
        +  apply iterate_mono_1 with 0; auto.
           * intros x y H; auto with arith.
           * intro x; auto.
           * intros; generalize (Rem2 n0); auto.
        + induction n; cbn; auto.
    Qed.
    (*||*)
    
    Lemma L5: P (S m). (* .no-goals *)
    Proof.
      repeat split.
      - apply Rem1.
      - apply Rem2.
      - apply Rem3.
    Qed. 

  End Induc_step.

  Lemma Ack_properties : forall m, P m.
  Proof.
    induction m.
    - apply P0.
    - apply L5; auto.
  Qed.

End Ack_Properties.


Lemma le_S_Ack m : fun_le S (Ack m).
Proof.
  destruct (Ack_properties m);tauto.
Qed.

Lemma Ack_strict_mono m : strict_mono (Ack m).
Proof.
  destruct (Ack_properties m);tauto.
Qed.



Lemma Ack_mono_l m n :   m <= n -> forall p,  Ack m p <= Ack n p.
Proof.
  induction 1; auto.
  intro p; transitivity (Ack m0 p); auto.
  destruct (Ack_properties m0) as [_ [_ H0]]; auto.
Qed.

Lemma Ack_mono_r m: forall n p, n <= p -> Ack m n <= Ack m p.
Proof.
  intros; apply Ack_m_mono_weak; trivial.
  apply Ack_properties.  
Qed.


(*| The following inequality is applied in the proof that [Ack] is not primitive    recursive, allowing to simplify  patterns of the form [Ack _ (Ack _ _)].
|*)
Section Proof_of_nested_Ack_bound.

  Remark R0 (m:nat): forall n, 2 + n <= Ack (2+m) n.
  (*| .. coq:: none |*)
  Proof.
    induction m.
    -  intros; simpl (2+0).
       induction n; auto with arith.
       rewrite     Ack_S_S.
       transitivity (Ack 0 (Ack 2 n)).
       +  rewrite Ack_0; lia.
       +  apply Ack_mono_l; auto.
    - replace (2 + S m) with (S (2 + m)) by lia.
      destruct (Ack_properties (2+m)) as [_ [H1 H2]]. 
      intro n; transitivity (Ack (2 + m) n); auto.
  Qed.
 (*||*)
  
  Remark R1 : forall m n, Ack (S m) (S n) <= Ack (2 + m) n.
  (*| .. coq:: none |*)
  Proof. 
    intro; destruct n; simpl (2 + m).
    -   rewrite Ack_S_0; left.
    -  rewrite (Ack_S_S  (S m));
         generalize (R0 m n ); intro H;  apply Ack_mono_r; auto.
  Qed.
  (*||*)

  Remark R2 (m n:nat) : Ack m (Ack m n) <= Ack (S m) (S n).
  (*| .. coq:: none |*)
  Proof.
    destruct (Ack_properties m) as [H1 [H2 H3]].
    transitivity (Ack m (Ack (S m) n)); auto.
    - apply Ack_mono_r.  
      +  apply H3; rewrite <- Ack_S_S; auto.
  Qed.
  (*||*)
  
  Remark R3 (m n:nat) : Ack m (Ack m n) <= Ack (S (S m)) n.
   (*| .. coq:: none |*)
  Proof.
    transitivity (Ack (S m) (S n)).
    - apply R2.
    - apply R1.
  Qed.
  (*||*)
  
  Lemma nested_Ack_bound : forall k m n,
      Ack k (Ack m n) <= Ack (2 + max k m) n.
  Proof.
    intros; remember (Nat.max k m) as x.
    - assert (H: m <= x) by lia;
        assert (H0: k <= x) by lia.
      (* ... *)
      (*| .. coq:: none |*)
      simpl (2 + x); transitivity (Ack x (Ack m n)). 
      +  apply Ack_mono_l; auto.
      +  transitivity (Ack x (Ack  x n)).
         *  apply Ack_mono_r.
            apply Ack_mono_l; lia.
         * apply R3.
      (*||*)
  Qed.

End Proof_of_nested_Ack_bound.

Lemma Ack_Sn_plus : forall n p, S n + p < Ack (S n) p.
Proof.
  induction n.
  (* ... *) (*| .. coq:: none |*)
  -  intro; rewrite Ack_1_n; lia.
  -  induction p.
     + rewrite Ack_S_0.
       specialize (IHn 1); lia.
     + rewrite Ack_S_S.
       assert   (Ack (S (S n)) p < Ack (S n) (Ack (S (S n)) p)).
       {
         destruct (Ack_properties (S n)) as [H [H0 H1]];  apply H0.
       }
       eapply Lt.le_lt_trans with (2:= H).
       replace (S (S n) + S p) with (S (S (S n) + p)) by lia.
       apply IHp.
  (*||*)
Qed.

(*| 

[Ack] is (partially) strictly monotonous in its first argument  

|*)

Remark R5 m n :  Ack m (S n) < Ack (S m) (S n).
Proof.
  rewrite Ack_S_S; apply Ack_strict_mono.
  (* ... *) (*| .. coq:: none |*)
  apply Lt.le_lt_trans with (S m + n).
  -  lia.
  -  apply Ack_Sn_plus.
  (*||*)
Qed.

Lemma Ack_strict_mono_l n m p :
  n < m -> Ack n (S p) < Ack m (S p).
Proof.
  induction 1.
  -  apply R5.
  -  transitivity (Ack m (S p)); auto.
     apply R5.
Qed.

(*| .. coq:: none |*)

(* 

To remove ?
============


 Ackermann function as a 2nd-order iteration  (two versions) 

*)

Definition phi_Ack (f : nat -> nat) (k : nat) :=
  iterate f (S k) 1.

Definition phi_Ack' (f : nat -> nat) (k : nat) :=
  iterate f  k (f 1).

Lemma phi_Ack'_ext f g: (forall x, f x = g x) ->
                        forall p,  phi_Ack' f p = phi_Ack' g p.
Proof.
  induction p.      
  -  cbn; auto.
  -  cbn;  unfold phi_Ack' in IHp;  rewrite IHp;  apply H.
Qed.

Lemma phi_phi'_Ack : forall f k,
    phi_Ack f k = phi_Ack' f k.
Proof.
  unfold phi_Ack, phi_Ack'; intros;  now rewrite iterate_S_eqn2.
Qed.


Lemma Ack_paraphrase : forall m ,  Ack m  =
                                   match m with
                                   | 0 => S 
                                   | S p =>  phi_Ack  (Ack p) 
                                   end.
Proof.
  destruct m; reflexivity.
Qed.

Lemma Ack_paraphrase' : forall m k,  Ack m  k=
                                     match m with
                                     | 0 => S k
                                     | S p =>  phi_Ack'  (Ack p) k
                                     end.
Proof.
  destruct m.
  - reflexivity.
  - intro k; rewrite <- phi_phi'_Ack; reflexivity.
Qed.

Lemma Ack_as_iter' : forall m p, Ack m p = iterate phi_Ack' m S p.
Proof.
  induction  m.
  - reflexivity.
  -intro p; rewrite Ack_paraphrase', iterate_S_eqn.
   apply phi_Ack'_ext; auto.
Qed.


Lemma Ack_as_iter : forall m , Ack m  = iterate phi_Ack m S.
Proof.
  induction  m.
  - reflexivity.
  - rewrite Ack_paraphrase, iterate_S_eqn; now rewrite IHm.
Qed.


(*||*)
