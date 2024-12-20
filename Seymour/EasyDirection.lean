import Mathlib.Data.Matroid.IndepAxioms
import Seymour.ForMathlib.MatrixTU
import Seymour.Mathlib.Sets

open scoped Matrix


section custom_notation

/-- The finite field on two elements; write `Z2` for "value" type but `Fin 2` for "indexing" type. -/
abbrev Z2 : Type := ZMod 2

/-- Roughly speaking `a ᕃ A = A ∪ {a}`. -/
infixr:66 " ᕃ " => Insert.insert -- TODO (low priority) use `syntax` and write a custom delaborator

/-- Writing `X ⫗ Y` is slightly more general than writing `X ∩ Y = ∅`. -/
infix:61 " ⫗ " => Disjoint

end custom_notation


section binary_matroid_data

/-- Data describing a binary matroid on the ground set `X ∪ Y` where `X` and `Y` are bundled. -/
structure BinaryMatroid (α : Type*) [DecidableEq α] where
  X : Set α
  Y : Set α
  decmemX : ∀ a, Decidable (a ∈ X)
  decmemY : ∀ a, Decidable (a ∈ Y)
  hXY : X ⫗ Y
  B : Matrix X Y Z2

attribute [instance] BinaryMatroid.decmemX
attribute [instance] BinaryMatroid.decmemY

end binary_matroid_data


variable {α : Type*}

section binary_matroid_matroid

variable {X Y : Set α}

def HasSubset.Subset.elem (hXY : X ⊆ Y) (x : X.Elem) : Y.Elem :=
  ⟨x.val, hXY x.property⟩

variable [∀ a, Decidable (a ∈ X)] [∀ a, Decidable (a ∈ Y)]
-- Note that `variable [DecidablePred X.Mem] [DecidablePred Y.Mem]` does not work.

def Subtype.toSum (i : (X ∪ Y).Elem) : X.Elem ⊕ Y.Elem :=
  if hiX : i.val ∈ X then Sum.inl ⟨i, hiX⟩ else
  if hiY : i.val ∈ Y then Sum.inr ⟨i, hiY⟩ else
  (i.property.elim hiX hiY).elim


variable [DecidableEq α]

/-- Given matrix `B`, is the set of columns `S` in the (standard) representation [`1` | `B`] `Z2`-independent? -/
def Matrix.IndepCols (B : Matrix X Y Z2) (S : Set α) : Prop :=
  ∃ hs : S ⊆ X ∪ Y,
    LinearIndependent Z2 ((Matrix.fromColumns 1 B).submatrix id (Subtype.toSum ∘ hs.elem)).transpose

-- In the following five theorems `B` must stay explicit.

/-- The empty set of columns in linearly independent. -/
theorem Matrix.IndepCols_empty (B : Matrix X Y Z2) : B.IndepCols ∅ := by
  use Set.empty_subset (X ∪ Y)
  exact linearIndependent_empty_type

/-- A subset of a linearly independent set of columns in linearly independent. -/
theorem Matrix.IndepCols_subset (B : Matrix X Y Z2) (I J : Set α) (hBJ : B.IndepCols J) (hIJ : I ⊆ J) :
    B.IndepCols I := by
  obtain ⟨hJ, hB⟩ := hBJ
  use hIJ.trans hJ
  let I' := { i : J.Elem // i.val ∈ I }
  let e : I' ≃ I := (Equiv.subtypeSubtypeEquivSubtype (by convert hIJ))
  sorry

/-- A nonmaximal linearly independent set of columns can be augmented with another linearly independent column. -/
theorem Matrix.IndepCols_aug (B : Matrix X Y Z2) (I J : Set α)
    (hBI : B.IndepCols I) (nonmax : ¬Maximal B.IndepCols I) (hBJ : Maximal B.IndepCols J) :
    ∃ x ∈ J \ I, B.IndepCols (x ᕃ I) := by
  sorry

/-- Any set of columns has the maximal subset property. -/
theorem Matrix.IndepCols_maximal (B : Matrix X Y Z2) (S : Set α) :
    Matroid.ExistsMaximalSubsetProperty B.IndepCols S := by
  sorry


/-- Binary matroid generated by its standard representation matrix, expressed as `IndepMatroid`. -/
def Matrix.toIndepMatroid (B : Matrix X Y Z2) : IndepMatroid α where
  E := X ∪ Y
  Indep := B.IndepCols
  indep_empty := B.IndepCols_empty
  indep_subset := B.IndepCols_subset
  indep_aug := B.IndepCols_aug
  indep_maximal S _ := B.IndepCols_maximal S
  subset_ground _ := Exists.fst

/-- Binary matroid generated by its standard representation matrix, expressed as `Matroid`. -/
def Matrix.toMatroid (B : Matrix X Y Z2) : Matroid α := B.toIndepMatroid.matroid

omit X Y

def BinaryMatroid.toMatroid (M : BinaryMatroid α) :=
  M.B.toMatroid

@[simp]
lemma BinaryMatroid.indep_eq (M : BinaryMatroid α) : M.toMatroid.Indep = M.B.IndepCols :=
  rfl

instance : Coe (BinaryMatroid α) (Matroid α) where
  coe := BinaryMatroid.toMatroid

/-- The binary matroid on the ground set `X ∪ Y` is regular. -/
def BinaryMatroid.IsRegular (M : BinaryMatroid α) : Prop :=
  ∃ B' : Matrix M.X M.Y ℤ, -- signed version of `B`
    (Matrix.fromColumns (1 : Matrix M.X M.X ℤ) B').TU ∧ -- the signed representation matrix is totally unimodular
    ∀ i : M.X, ∀ j : M.Y, if M.B i j = 0 then B' i j = 0 else B' i j = 1 ∨ B' i j = -1 -- in absolulute values `B' = B`

end binary_matroid_matroid


section sums_matrix_level

variable {X₁ Y₁ : Set α} {X₂ Y₂ : Set α} {β : Type*} [CommRing β]

/-- Matrix-level 1-sum for matroids defined by their standard representation matrices. -/
abbrev Matrix.oneSumComposition (A₁ : Matrix X₁ Y₁ β) (A₂ : Matrix X₂ Y₂ β) :
    Matrix (X₁ ⊕ X₂) (Y₁ ⊕ Y₂) β :=
  Matrix.fromBlocks A₁ 0 0 A₂

/-- Matrix-level 2-sum for matroids defined by their standard representation matrices; does not check legitimacy. -/
abbrev Matrix.twoSumComposition (A₁ : Matrix X₁ Y₁ β) (x : Y₁ → β) (A₂ : Matrix X₂ Y₂ β) (y : X₂ → β) :
    Matrix (X₁ ⊕ X₂) (Y₁ ⊕ Y₂) β :=
  Matrix.fromBlocks A₁ 0 (fun i j => y i * x j) A₂

/-- Matrix-level 3-sum for matroids defined by their standard representation matrices; does not check legitimacy. -/
noncomputable abbrev Matrix.threeSumComposition (A₁ : Matrix X₁ (Y₁ ⊕ Fin 2) β) (A₂ : Matrix (Fin 2 ⊕ X₂) Y₂ β)
    (z₁ : Y₁ → β) (z₂ : X₂ → β) (D : Matrix (Fin 2) (Fin 2) β) (D₁ : Matrix (Fin 2) Y₁ β) (D₂ : Matrix X₂ (Fin 2) β) :
    Matrix ((X₁ ⊕ Unit) ⊕ (Fin 2 ⊕ X₂)) ((Y₁ ⊕ Fin 2) ⊕ (Unit ⊕ Y₂)) β :=
  -- Unfortunately `Ring.inverse` is `noncomputable` and upgrading `β` to `Field` does not help.
  let D₁₂ : Matrix X₂ Y₁ β := D₂ * D⁻¹ * D₁
  Matrix.fromBlocks
    (Matrix.fromRows A₁ (Matrix.row Unit (Sum.elim z₁ ![1, 1]))) 0
    (Matrix.fromBlocks D₁ D D₁₂ D₂) (Matrix.fromColumns (Matrix.col Unit (Sum.elim ![1, 1] z₂)) A₂)

end sums_matrix_level


section matrix_conversions

variable {T₁ T₂ S₁ S₂ : Set α} {β : Type*}
  [∀ a, Decidable (a ∈ T₁)]
  [∀ a, Decidable (a ∈ T₂)]
  [∀ a, Decidable (a ∈ S₁)]
  [∀ a, Decidable (a ∈ S₂)]

def Matrix.toMatrixUnionUnion (C : Matrix (T₁.Elem ⊕ T₂.Elem) (S₁.Elem ⊕ S₂.Elem) β) :
    Matrix (T₁ ∪ T₂).Elem (S₁ ∪ S₂).Elem β :=
  ((C ∘ Subtype.toSum) · ∘ Subtype.toSum)

variable {T S : Set α}

def Matrix.toMatrixElemElem (C : Matrix (T₁ ⊕ T₂) (S₁ ⊕ S₂) β) (hT : T = T₁ ∪ T₂) (hS : S = S₁ ∪ S₂) :
    Matrix T S β :=
  hT ▸ hS ▸ C.toMatrixUnionUnion

lemma Matrix.toMatrixElemElem_eq (C : Matrix (T₁ ⊕ T₂) (S₁ ⊕ S₂) β) (hT : T = T₁ ∪ T₂) (hS : S = S₁ ∪ S₂) :
    C.toMatrixElemElem hT hS = Matrix.of (fun i j => C (hT ▸ i).toSum (hS ▸ j).toSum) := by
  subst hT hS
  rfl

lemma Matrix.TU.toMatrixUnionUnion {C : Matrix (T₁ ⊕ T₂) (S₁ ⊕ S₂) ℤ} (hC : C.TU) :
    C.toMatrixUnionUnion.TU := by
  rw [Matrix.TU_iff] at hC ⊢
  intros
  apply hC

lemma Matrix.TU.toMatrixElemElem {C : Matrix (T₁ ⊕ T₂) (S₁ ⊕ S₂) ℤ} (hC : C.TU) (hT : T = T₁ ∪ T₂) (hS : S = S₁ ∪ S₂) :
    (C.toMatrixElemElem hT hS).TU :=
  hT ▸ hS ▸ hC.toMatrixUnionUnion

end matrix_conversions


variable [DecidableEq α]

section sums_matroid_level

variable {M₁ M₂ : BinaryMatroid α}

/-- BinaryMatroid-level 1-sum of two matroids. It checks that everything is disjoint (returned as `.snd` of the output). -/
def BinaryMatroid.oneSum (hXY : M₁.X ⫗ M₂.Y) (hYX : M₁.Y ⫗ M₂.X) :
    BinaryMatroid α × Prop :=
  ⟨
    ⟨
      M₁.X ∪ M₂.X,
      M₁.Y ∪ M₂.Y,
      inferInstance,
      inferInstance,
      by simp only [Set.disjoint_union_left, Set.disjoint_union_right]; exact ⟨⟨M₁.hXY, hYX.symm⟩, ⟨hXY, M₂.hXY⟩⟩,
      (Matrix.oneSumComposition M₁.B M₂.B).toMatrixUnionUnion
    ⟩,
    M₁.X ⫗ M₂.X ∧ M₁.Y ⫗ M₂.Y
  ⟩

/-- BinaryMatroid-level 2-sum of two matroids.
Second part check legitimacy: the ground sets of `M₁` and `M₂` are disjoint except for element `a` that lies in `M₁.X ∩ M₂.Y`,
and the bottom-most row of `M₁` and the left-most column of `M₂` are each nonzero vectors. -/
def BinaryMatroid.twoSum {a : α} (ha : M₁.X ∩ M₂.Y = {a}) (hXY : M₂.X ⫗ M₁.Y) :
    BinaryMatroid α × Prop :=
  let A₁ : Matrix (M₁.X \ {a}).Elem M₁.Y.Elem Z2 := M₁.B ∘ Set.diff_subset.elem -- the top submatrix of `B₁`
  let A₂ : Matrix M₂.X.Elem (M₂.Y \ {a}).Elem Z2 := (M₂.B · ∘ Set.diff_subset.elem) -- the right submatrix of `B₂`
  let x : M₁.Y.Elem → Z2 := M₁.B ⟨a, Set.mem_of_mem_inter_left (by rw [ha]; rfl)⟩ -- the bottom row of `B₁`
  let y : M₂.X.Elem → Z2 := (M₂.B · ⟨a, Set.mem_of_mem_inter_right (by rw [ha]; rfl)⟩) -- the left column of `B₂`
  ⟨
    ⟨
      (M₁.X \ {a}) ∪ M₂.X,
      M₁.Y ∪ (M₂.Y \ {a}),
      inferInstance,
      inferInstance,
      by
        rw [Set.disjoint_union_right, Set.disjoint_union_left, Set.disjoint_union_left]
        exact ⟨⟨M₁.hXY.disjoint_sdiff_left, hXY⟩, ⟨disjoint_of_singleton_intersection_both_wo ha, M₂.hXY.disjoint_sdiff_right⟩⟩,
      (Matrix.twoSumComposition A₁ x A₂ y).toMatrixUnionUnion
    ⟩,
    (M₁.X ⫗ M₂.X ∧ M₁.Y ⫗ M₂.Y) ∧ (x ≠ 0 ∧ y ≠ 0)
  ⟩

/-- BinaryMatroid-level 3-sum of two matroids.
Second part check legitimacy: some very specific conditions about the standard representation matrices. -/
noncomputable def BinaryMatroid.threeSum {x₁ x₂ x₃ y₁ y₂ y₃ : α}
    (hXX : M₁.X ∩ M₂.X = {x₁, x₂, x₃}) (hYY : M₁.Y ∩ M₂.Y = {y₁, y₂, y₃}) (hXY : M₁.X ⫗ M₂.Y) (hYX : M₁.Y ⫗ M₂.X) :
    BinaryMatroid α × Prop :=
  have hxxx₁ : {x₁, x₂, x₃} ⊆ M₁.X := hXX.symm.subset.trans Set.inter_subset_left
  have hxxx₂ : {x₁, x₂, x₃} ⊆ M₂.X := hXX.symm.subset.trans Set.inter_subset_right
  have hyyy₁ : {y₁, y₂, y₃} ⊆ M₁.Y := hYY.symm.subset.trans Set.inter_subset_left
  have hyyy₂ : {y₁, y₂, y₃} ⊆ M₂.Y := hYY.symm.subset.trans Set.inter_subset_right
  have x₁inX₁ : x₁ ∈ M₁.X := hxxx₁ (Set.mem_insert x₁ {x₂, x₃})
  have x₁inX₂ : x₁ ∈ M₂.X := hxxx₂ (Set.mem_insert x₁ {x₂, x₃})
  have x₂inX₁ : x₂ ∈ M₁.X := hxxx₁ (Set.insert_comm x₁ x₂ {x₃} ▸ Set.mem_insert x₂ {x₁, x₃})
  have x₂inX₂ : x₂ ∈ M₂.X := hxxx₂ (Set.insert_comm x₁ x₂ {x₃} ▸ Set.mem_insert x₂ {x₁, x₃})
  have x₃inX₁ : x₃ ∈ M₁.X := hxxx₁ (by simp)
  have x₃inX₂ : x₃ ∈ M₂.X := hxxx₂ (by simp)
  have y₃inY₁ : y₃ ∈ M₁.Y := hyyy₁ (by simp)
  have y₃inY₂ : y₃ ∈ M₂.Y := hyyy₂ (by simp)
  have y₂inY₁ : y₂ ∈ M₁.Y := hyyy₁ (Set.insert_comm y₁ y₂ {y₃} ▸ Set.mem_insert y₂ {y₁, y₃})
  have y₂inY₂ : y₂ ∈ M₂.Y := hyyy₂ (Set.insert_comm y₁ y₂ {y₃} ▸ Set.mem_insert y₂ {y₁, y₃})
  have y₁inY₁ : y₁ ∈ M₁.Y := hyyy₁ (Set.mem_insert y₁ {y₂, y₃})
  have y₁inY₂ : y₁ ∈ M₂.Y := hyyy₂ (Set.mem_insert y₁ {y₂, y₃})
  -- The actual definition starts here:
  let A₁ : Matrix (M₁.X \ {x₁, x₂, x₃}).Elem ((M₁.Y \ {y₁, y₂, y₃}).Elem ⊕ Fin 2) Z2 := -- the top left submatrix
    (fun i j => M₁.B ⟨i.val, Set.mem_of_mem_diff i.property⟩
        (j.casesOn (fun j' => ⟨j'.val, Set.mem_of_mem_diff j'.property⟩) ![⟨y₂, y₂inY₁⟩, ⟨y₁, y₁inY₁⟩]))
  let A₂ : Matrix (Fin 2 ⊕ (M₂.X \ {x₁, x₂, x₃}).Elem) (M₂.Y \ {y₁, y₂, y₃}).Elem Z2 := -- the bottom right submatrix
    (fun i j => M₂.B (i.casesOn ![⟨x₂, x₂inX₂⟩, ⟨x₃, x₃inX₂⟩] (fun i' => ⟨i'.val, Set.mem_of_mem_diff i'.property⟩))
        ⟨j.val, Set.mem_of_mem_diff j.property⟩)
  let z₁ : (M₁.Y \ {y₁, y₂, y₃}).Elem → Z2 := -- the middle left "row vector"
    (fun j => M₁.B ⟨x₁, x₁inX₁⟩ ⟨j.val, Set.mem_of_mem_diff j.property⟩)
  let z₂ : (M₂.X \ {x₁, x₂, x₃}).Elem → Z2 := -- the bottom middle "column vector"
    (fun i => M₂.B ⟨i.val, Set.mem_of_mem_diff i.property⟩ ⟨y₃, y₃inY₂⟩)
  let D_₁ : Matrix (Fin 2) (Fin 2) Z2 := -- the bottom middle 2x2 submatrix
    (fun i j => M₁.B (![⟨x₂, x₂inX₁⟩, ⟨x₃, x₃inX₁⟩] i) (![⟨y₂, y₂inY₁⟩, ⟨y₁, y₁inY₁⟩] j))
  let D_₂ : Matrix (Fin 2) (Fin 2) Z2 := -- the middle left 2x2 submatrix
    (fun i j => M₂.B (![⟨x₂, x₂inX₂⟩, ⟨x₃, x₃inX₂⟩] i) (![⟨y₂, y₂inY₂⟩, ⟨y₁, y₁inY₂⟩] j))
  let D₁ : Matrix (Fin 2) (M₁.Y \ {y₁, y₂, y₃}).Elem Z2 := -- the bottom left submatrix
    (fun i j => M₁.B (![⟨x₂, x₂inX₁⟩, ⟨x₃, x₃inX₁⟩] i) ⟨j.val, Set.mem_of_mem_diff j.property⟩)
  let D₂ : Matrix (M₂.X \ {x₁, x₂, x₃}).Elem (Fin 2) Z2 := -- the bottom left submatrix
    (fun i j => M₂.B ⟨i.val, Set.mem_of_mem_diff i.property⟩ (![⟨y₂, y₂inY₂⟩, ⟨y₁, y₁inY₂⟩] j))
  ⟨
    ⟨
      (M₁.X \ {x₁, x₂, x₃}) ∪ M₂.X,
      M₁.Y ∪ (M₂.Y \ {y₁, y₂, y₃}),
      inferInstance,
      inferInstance,
      by
        rw [Set.disjoint_union_right, Set.disjoint_union_left, Set.disjoint_union_left]
        exact
          ⟨⟨M₁.hXY.disjoint_sdiff_left, hYX.symm⟩, ⟨hXY.disjoint_sdiff_right.disjoint_sdiff_left, M₂.hXY.disjoint_sdiff_right⟩⟩,
      Matrix.of (fun i j =>
        Matrix.threeSumComposition A₁ A₂ z₁ z₂ D_₁ D₁ D₂ (
          if hi₁ : i.val ∈ M₁.X \ {x₁, x₂, x₃} then Sum.inl (Sum.inl ⟨i, hi₁⟩) else
          if hi₂ : i.val ∈ M₂.X \ {x₁, x₂, x₃} then Sum.inr (Sum.inr ⟨i, hi₂⟩) else
          if hx₁ : i.val = x₁ then Sum.inl (Sum.inr ()) else
          if hx₂ : i.val = x₂ then Sum.inr (Sum.inl 0) else
          if hx₃ : i.val = x₃ then Sum.inr (Sum.inl 1) else
          (i.property.elim hi₁ (by simp_all)).elim
          -- TODO can `Matrix.toMatrixUnionUnion` be combined with something else to simplify this definition?
        ) (
          if hj₁ : j.val ∈ M₁.Y \ {y₁, y₂, y₃} then Sum.inl (Sum.inl ⟨j, hj₁⟩) else
          if hj₂ : j.val ∈ M₂.Y \ {y₁, y₂, y₃} then Sum.inr (Sum.inr ⟨j, hj₂⟩) else
          if hy₁ : j.val = y₁ then Sum.inl (Sum.inr 1) else
          if hy₂ : j.val = y₂ then Sum.inl (Sum.inr 0) else
          if hy₃ : j.val = y₃ then Sum.inr (Sum.inl ()) else
          (j.property.elim (by simp_all) hj₂).elim
        )
      )
    ⟩,
    IsUnit D_₁ ∧ D_₁ = D_₂ -- the matrix `D_₁ = D_₂` (called D-bar in the book) is invertible
    ∧ M₁.B ⟨x₁, x₁inX₁⟩ ⟨y₁, y₁inY₁⟩ = 1
    ∧ M₁.B ⟨x₁, x₁inX₁⟩ ⟨y₂, y₂inY₁⟩ = 1
    ∧ M₁.B ⟨x₂, x₂inX₁⟩ ⟨y₃, y₃inY₁⟩ = 1
    ∧ M₁.B ⟨x₃, x₃inX₁⟩ ⟨y₃, y₃inY₁⟩ = 1
    ∧ M₂.B ⟨x₁, x₁inX₂⟩ ⟨y₁, y₁inY₂⟩ = 1
    ∧ M₂.B ⟨x₁, x₁inX₂⟩ ⟨y₂, y₂inY₂⟩ = 1
    ∧ M₂.B ⟨x₂, x₂inX₂⟩ ⟨y₃, y₃inY₂⟩ = 1
    ∧ M₂.B ⟨x₃, x₃inX₂⟩ ⟨y₃, y₃inY₂⟩ = 1
    ∧ (∀ x : α, ∀ hx : x ∈ M₁.X, x ≠ x₂ ∧ x ≠ x₃ → M₁.B ⟨x, hx⟩ ⟨y₃, y₃inY₁⟩ = 0) -- the rest of the rightmost column is `0`s
    ∧ (∀ y : α, ∀ hy : y ∈ M₂.Y, y ≠ y₂ ∧ y ≠ y₁ → M₂.B ⟨x₁, x₁inX₂⟩ ⟨y, hy⟩ = 0) -- the rest of the topmost row is `0`s
  ⟩

end sums_matroid_level


section sums_propositional_level

/-- Matroid `M` is a result of 1-summing `M₁` and `M₂` (should be equivalent to direct sums). -/
def BinaryMatroid.Is1sumOf (M : BinaryMatroid α) (M₁ M₂ : BinaryMatroid α) : Prop :=
  ∃ hXY : M₁.X ⫗ M₂.Y, ∃ hYX : M₁.Y ⫗ M₂.X,
    let M₀ := BinaryMatroid.oneSum hXY hYX
    M = M₀.fst ∧ M₀.snd

/-- Matroid `M` is a result of 2-summing `M₁` and `M₂` in some way. -/
def BinaryMatroid.Is2sumOf (M : BinaryMatroid α) (M₁ M₂ : BinaryMatroid α) : Prop :=
  ∃ a : α, ∃ ha : M₁.X ∩ M₂.Y = {a}, ∃ hXY : M₂.X ⫗ M₁.Y,
    let M₀ := BinaryMatroid.twoSum ha hXY
    M = M₀.fst ∧ M₀.snd

/-- Matroid `M` is a result of 3-summing `M₁` and `M₂` in some way. -/
def BinaryMatroid.Is3sumOf (M : BinaryMatroid α) (M₁ M₂ : BinaryMatroid α) : Prop :=
  ∃ x₁ x₂ x₃ y₁ y₂ y₃ : α,
    ∃ hXX : M₁.X ∩ M₂.X = {x₁, x₂, x₃}, ∃ hYY : M₁.Y ∩ M₂.Y = {y₁, y₂, y₃}, ∃ hXY : M₁.X ⫗ M₂.Y, ∃ hYX : M₁.Y ⫗ M₂.X,
      let M₀ := BinaryMatroid.threeSum hXX hYY hXY hYX
      M = M₀.fst ∧ M₀.snd

end sums_propositional_level


section API_for_matroid_sums

variable {M M₁ M₂ : BinaryMatroid α}

lemma BinaryMatroid.Is1sumOf.X_eq (hM : M.Is1sumOf M₁ M₂) :
    M.X = M₁.X ∪ M₂.X := by
  obtain ⟨_, _, rfl, -⟩ := hM
  rfl

lemma BinaryMatroid.Is1sumOf.Y_eq (hM : M.Is1sumOf M₁ M₂) :
    M.Y = M₁.Y ∪ M₂.Y := by
  obtain ⟨_, _, rfl, -⟩ := hM
  rfl

lemma BinaryMatroid.Is1sumOf.B_eq (hM : M.Is1sumOf M₁ M₂) :
    M.B = hM.X_eq ▸ hM.Y_eq ▸ (Matrix.oneSumComposition M₁.B M₂.B).toMatrixUnionUnion := by
  obtain ⟨_, _, rfl, -⟩ := hM
  rfl

lemma BinaryMatroid.Is2sumOf.disjoXX (hM : M.Is2sumOf M₁ M₂) :
    M₁.X ⫗ M₂.X := by
  obtain ⟨a, -, -, -, ⟨hXX, -⟩, -⟩ := hM
  exact hXX

lemma BinaryMatroid.Is2sumOf.disjoYY (hM : M.Is2sumOf M₁ M₂) :
    M₁.Y ⫗ M₂.Y := by
  obtain ⟨a, -, -, -, ⟨-, hYY⟩, -⟩ := hM
  exact hYY

lemma BinaryMatroid.Is2sumOf.interXY (hM : M.Is2sumOf M₁ M₂) :
    ∃ a : α, M₁.X ∩ M₂.Y = {a} := by
  obtain ⟨a, ha, -⟩ := hM
  exact ⟨a, ha⟩

lemma BinaryMatroid.Is2sumOf.disjoYX (hM : M.Is2sumOf M₁ M₂) :
    M₁.Y ⫗ M₂.X := by
  obtain ⟨a, -, hXY, -⟩ := hM
  exact hXY.symm

lemma BinaryMatroid.Is2sumOf.Indep (hM : M.Is2sumOf M₁ M₂) :
    ∃ a : α, ∃ ha : M₁.X ∩ M₂.Y = {a},
      let A₁ : Matrix (M₁.X \ {a}).Elem M₁.Y.Elem Z2 := M₁.B ∘ Set.diff_subset.elem -- the top submatrix of `B₁`
      let A₂ : Matrix M₂.X.Elem (M₂.Y \ {a}).Elem Z2 := (M₂.B · ∘ Set.diff_subset.elem) -- the right submatrix of `B₂`
      let x : M₁.Y.Elem → Z2 := M₁.B ⟨a, Set.mem_of_mem_inter_left (by rw [ha]; rfl)⟩ -- the bottom row of `B₁`
      let y : M₂.X.Elem → Z2 := (M₂.B · ⟨a, Set.mem_of_mem_inter_right (by rw [ha]; rfl)⟩) -- the left column of `B₂`
      (Matrix.twoSumComposition A₁ x A₂ y).toMatrixUnionUnion.IndepCols =
      M.toMatroid.Indep := by
  obtain ⟨a, ha, _, rfl, -⟩ := hM
  exact ⟨a, ha, rfl⟩

lemma BinaryMatroid.Is2sumOf.x_nonzero (hM : M.Is2sumOf M₁ M₂) :
    ∃ a : α, ∃ ha : M₁.X ∩ M₂.Y = {a},
      M₁.B ⟨a, Set.mem_of_mem_inter_left (by rw [ha]; rfl)⟩ ≠ 0 := by
  obtain ⟨a, ha, _, rfl, -, hx, -⟩ := hM
  exact ⟨a, ha, hx⟩

lemma BinaryMatroid.Is2sumOf.y_nonzero (hM : M.Is2sumOf M₁ M₂) :
    ∃ a : α, ∃ ha : M₁.X ∩ M₂.Y = {a},
      (M₂.B · ⟨a, Set.mem_of_mem_inter_right (by rw [ha]; rfl)⟩) ≠ 0 := by
  obtain ⟨a, ha, _, rfl, -, -, hy⟩ := hM
  exact ⟨a, ha, hy⟩

lemma BinaryMatroid.Is3sumOf.X_eq (hM : M.Is3sumOf M₁ M₂) :
    M.X = M₁.X ∪ M₂.X := by
  obtain ⟨_, _, _, _, _, _, hXX, _, _, _, rfl, -⟩ := hM
  simp [BinaryMatroid.threeSum, ←hXX, setminus_inter_union_eq_union]

lemma BinaryMatroid.Is3sumOf.Y_eq (hM : M.Is3sumOf M₁ M₂) :
    M.Y = M₁.Y ∪ M₂.Y := by
  obtain ⟨_, _, _, _, _, _, _, hYY, _, _, rfl, -⟩ := hM
  simp [BinaryMatroid.threeSum, ←hYY, setminus_inter_union_eq_union]

lemma BinaryMatroid.Is3sumOf.interXX (hM : M.Is3sumOf M₁ M₂) :
    ∃ x₁ x₂ x₃ : α, M₁.X ∩ M₂.X = {x₁, x₂, x₃} := by
  obtain ⟨x₁, x₂, x₃, -, -, -, hXX, -⟩ := hM
  exact ⟨x₁, x₂, x₃, hXX⟩

lemma BinaryMatroid.Is3sumOf.interYY (hM : M.Is3sumOf M₁ M₂) :
    ∃ y₁ y₂ y₃ : α, M₁.Y ∩ M₂.Y = {y₁, y₂, y₃} := by
  obtain ⟨-, -, -, y₁, y₂, y₃, -, hYY, -⟩ := hM
  exact ⟨y₁, y₂, y₃, hYY⟩

lemma BinaryMatroid.Is3sumOf.disjoXY (hM : M.Is3sumOf M₁ M₂) :
    M₁.X ⫗ M₂.Y := by
  obtain ⟨-, -, -, -, -, -, -, -, hXY, -⟩ := hM
  exact hXY

lemma BinaryMatroid.Is3sumOf.disjoYX (hM : M.Is3sumOf M₁ M₂) :
    M₁.Y ⫗ M₂.X := by
  obtain ⟨-, -, -, -, -, -, -, -, -, hYX, -⟩ := hM
  exact hYX

lemma BinaryMatroid.Is3sumOf.Indep (hM : M.Is3sumOf M₁ M₂) :
    ∃ x₁ x₂ x₃ y₁ y₂ y₃ : α,
    ∃ x₁inX₁ : x₁ ∈ M₁.X,
    ∃ x₂inX₁ : x₂ ∈ M₁.X,
    ∃ x₂inX₂ : x₂ ∈ M₂.X,
    ∃ x₃inX₁ : x₃ ∈ M₁.X,
    ∃ x₃inX₂ : x₃ ∈ M₂.X,
    ∃ y₃inY₂ : y₃ ∈ M₂.Y,
    ∃ y₂inY₁ : y₂ ∈ M₁.Y,
    ∃ y₂inY₂ : y₂ ∈ M₂.Y,
    ∃ y₁inY₁ : y₁ ∈ M₁.Y,
    ∃ y₁inY₂ : y₁ ∈ M₂.Y,
      let A₁ : Matrix (M₁.X \ {x₁, x₂, x₃}).Elem ((M₁.Y \ {y₁, y₂, y₃}).Elem ⊕ Fin 2) Z2 := -- the top left submatrix
        (fun i j => M₁.B ⟨i.val, Set.mem_of_mem_diff i.property⟩
            (j.casesOn (fun j' => ⟨j'.val, Set.mem_of_mem_diff j'.property⟩) ![⟨y₂, y₂inY₁⟩, ⟨y₁, y₁inY₁⟩]))
      let A₂ : Matrix (Fin 2 ⊕ (M₂.X \ {x₁, x₂, x₃}).Elem) (M₂.Y \ {y₁, y₂, y₃}).Elem Z2 := -- the bottom right submatrix
        (fun i j => M₂.B (i.casesOn ![⟨x₂, x₂inX₂⟩, ⟨x₃, x₃inX₂⟩] (fun i' => ⟨i'.val, Set.mem_of_mem_diff i'.property⟩))
            ⟨j.val, Set.mem_of_mem_diff j.property⟩)
      let z₁ : (M₁.Y \ {y₁, y₂, y₃}).Elem → Z2 := -- the middle left "row vector"
        (fun j => M₁.B ⟨x₁, x₁inX₁⟩ ⟨j.val, Set.mem_of_mem_diff j.property⟩)
      let z₂ : (M₂.X \ {x₁, x₂, x₃}).Elem → Z2 := -- the bottom middle "column vector"
        (fun i => M₂.B ⟨i.val, Set.mem_of_mem_diff i.property⟩ ⟨y₃, y₃inY₂⟩)
      let D_₁ : Matrix (Fin 2) (Fin 2) Z2 := -- the bottom middle 2x2 submatrix
        (fun i j => M₁.B (![⟨x₂, x₂inX₁⟩, ⟨x₃, x₃inX₁⟩] i) (![⟨y₂, y₂inY₁⟩, ⟨y₁, y₁inY₁⟩] j))
      let D₁ : Matrix (Fin 2) (M₁.Y \ {y₁, y₂, y₃}).Elem Z2 := -- the bottom left submatrix
        (fun i j => M₁.B (![⟨x₂, x₂inX₁⟩, ⟨x₃, x₃inX₁⟩] i) ⟨j.val, Set.mem_of_mem_diff j.property⟩)
      let D₂ : Matrix (M₂.X \ {x₁, x₂, x₃}).Elem (Fin 2) Z2 := -- the bottom left submatrix
        (fun i j => M₂.B ⟨i.val, Set.mem_of_mem_diff i.property⟩ (![⟨y₂, y₂inY₂⟩, ⟨y₁, y₁inY₂⟩] j))
      (Matrix.of (
        fun i : ((M₁.X \ {x₁, x₂, x₃}) ∪ M₂.X).Elem =>
        fun j : (M₁.Y ∪ (M₂.Y \ {y₁, y₂, y₃})).Elem =>
          Matrix.threeSumComposition A₁ A₂ z₁ z₂ D_₁ D₁ D₂ (
            if hi₁ : i.val ∈ M₁.X \ {x₁, x₂, x₃} then Sum.inl (Sum.inl ⟨i, hi₁⟩) else
            if hi₂ : i.val ∈ M₂.X \ {x₁, x₂, x₃} then Sum.inr (Sum.inr ⟨i, hi₂⟩) else
            if hx₁ : i.val = x₁ then Sum.inl (Sum.inr ()) else
            if hx₂ : i.val = x₂ then Sum.inr (Sum.inl 0) else
            if hx₃ : i.val = x₃ then Sum.inr (Sum.inl 1) else
            (i.property.elim hi₁ (by simp_all)).elim
          ) (
            if hj₁ : j.val ∈ M₁.Y \ {y₁, y₂, y₃} then Sum.inl (Sum.inl ⟨j, hj₁⟩) else
            if hj₂ : j.val ∈ M₂.Y \ {y₁, y₂, y₃} then Sum.inr (Sum.inr ⟨j, hj₂⟩) else
            if hy₁ : j.val = y₁ then Sum.inl (Sum.inr 1) else
            if hy₂ : j.val = y₂ then Sum.inl (Sum.inr 0) else
            if hy₃ : j.val = y₃ then Sum.inr (Sum.inl ()) else
            (j.property.elim (by simp_all) hj₂).elim
          )
        )
      ).IndepCols = M.toMatroid.Indep := by
  obtain ⟨x₁, x₂, x₃, y₁, y₂, y₃, hXX, hYY, -, -, rfl, -⟩ := hM
  have hxxx₁ : {x₁, x₂, x₃} ⊆ M₁.X := hXX.symm.subset.trans Set.inter_subset_left
  have hxxx₂ : {x₁, x₂, x₃} ⊆ M₂.X := hXX.symm.subset.trans Set.inter_subset_right
  have hyyy₁ : {y₁, y₂, y₃} ⊆ M₁.Y := hYY.symm.subset.trans Set.inter_subset_left
  have hyyy₂ : {y₁, y₂, y₃} ⊆ M₂.Y := hYY.symm.subset.trans Set.inter_subset_right
  exact ⟨x₁, x₂, x₃, y₁, y₂, y₃,
    hxxx₁ (Set.mem_insert x₁ {x₂, x₃}),
    hxxx₁ (Set.insert_comm x₁ x₂ {x₃} ▸ Set.mem_insert x₂ {x₁, x₃}),
    hxxx₂ (Set.insert_comm x₁ x₂ {x₃} ▸ Set.mem_insert x₂ {x₁, x₃}),
    hxxx₁ (by simp),
    hxxx₂ (by simp),
    hyyy₂ (by simp),
    hyyy₁ (Set.insert_comm y₁ y₂ {y₃} ▸ Set.mem_insert y₂ {y₁, y₃}),
    hyyy₂ (Set.insert_comm y₁ y₂ {y₃} ▸ Set.mem_insert y₂ {y₁, y₃}),
    hyyy₁ (Set.mem_insert y₁ {y₂, y₃}),
    hyyy₂ (Set.mem_insert y₁ {y₂, y₃}),
    rfl⟩

lemma BinaryMatroid.Is3sumOf.invertibilityDbar (hM : M.Is3sumOf M₁ M₂) :
    ∃ x₂ x₃ y₁ y₂ : α, ∃ x₂inX₁ : x₂ ∈ M₁.X, ∃ x₃inX₁ : x₃ ∈ M₁.X, ∃ y₂inY₁ : y₂ ∈ M₁.Y, ∃ y₁inY₁ : y₁ ∈ M₁.Y,
      IsUnit (Matrix.of (fun i j => M₁.B (![⟨x₂, x₂inX₁⟩, ⟨x₃, x₃inX₁⟩] i) (![⟨y₂, y₂inY₁⟩, ⟨y₁, y₁inY₁⟩] j))) := by
  obtain ⟨x₁, x₂, x₃, y₁, y₂, y₃, hXX, hYY, _, _, rfl, valid⟩ := hM
  use x₂, x₃, y₁, y₂
  have hxxx₁ : {x₁, x₂, x₃} ⊆ M₁.X := hXX.symm.subset.trans Set.inter_subset_left
  use hxxx₁ (Set.insert_comm x₁ x₂ {x₃} ▸ Set.mem_insert x₂ {x₁, x₃}), hxxx₁ (by simp)
  have hyyy₁ : {y₁, y₂, y₃} ⊆ M₁.Y := hYY.symm.subset.trans Set.inter_subset_left
  use hyyy₁ (Set.insert_comm y₁ y₂ {y₃} ▸ Set.mem_insert y₂ {y₁, y₃}), hyyy₁ (Set.mem_insert y₁ {y₂, y₃})
  unfold BinaryMatroid.threeSum at valid
  aesop

/- TODO missing API for all of the following parts of the 3-sum definition:
M₁.B ⟨x₁, x₁inX₁⟩ ⟨y₁, y₁inY₁⟩ = 1
M₁.B ⟨x₁, x₁inX₁⟩ ⟨y₂, y₂inY₁⟩ = 1
M₁.B ⟨x₂, x₂inX₁⟩ ⟨y₃, y₃inY₁⟩ = 1
M₁.B ⟨x₃, x₃inX₁⟩ ⟨y₃, y₃inY₁⟩ = 1
M₂.B ⟨x₁, x₁inX₂⟩ ⟨y₁, y₁inY₂⟩ = 1
M₂.B ⟨x₁, x₁inX₂⟩ ⟨y₂, y₂inY₂⟩ = 1
M₂.B ⟨x₂, x₂inX₂⟩ ⟨y₃, y₃inY₂⟩ = 1
M₂.B ⟨x₃, x₃inX₂⟩ ⟨y₃, y₃inY₂⟩ = 1
(∀ x : α, ∀ hx : x ∈ M₁.X, x ≠ x₂ ∧ x ≠ x₃ → M₁.B ⟨x, hx⟩ ⟨y₃, y₃inY₁⟩ = 0)
(∀ y : α, ∀ hy : y ∈ M₂.Y, y ≠ y₂ ∧ y ≠ y₁ → M₂.B ⟨x₁, x₁inX₂⟩ ⟨y, hy⟩ = 0)
-/
end API_for_matroid_sums


section lemmas_for_2sum

lemma Matrix_twoSumComposition_TU {X₁ Y₁ : Set α} {X₂ Y₂ : Set α} {A₁ : Matrix X₁ Y₁ ℤ} {A₂ : Matrix X₂ Y₂ ℤ}
    (hA₁ : A₁.TU) (hA₂ : A₂.TU) (x : Y₁ → ℤ) (y : X₂ → ℤ) :
    (Matrix.twoSumComposition A₁ x A₂ y).TU := by
  sorry -- Does it hold without further preconditions?

variable {M₁ M₂ : BinaryMatroid α} {a : α}

lemma BinaryMatroid_twoSum_B (ha : M₁.X ∩ M₂.Y = {a}) (hXY : M₂.X ⫗ M₁.Y) :
    ∃ haX₁ : a ∈ M₁.X, ∃ haY₂ : a ∈ M₂.Y,
      (BinaryMatroid.twoSum ha hXY).fst.B =
      (Matrix.twoSumComposition
        (M₁.B ∘ Set.diff_subset.elem)
        (M₁.B ⟨a, haX₁⟩)
        (M₂.B · ∘ Set.diff_subset.elem)
        (M₂.B · ⟨a, haY₂⟩)
      ).toMatrixUnionUnion :=
  have haXY : a ∈ M₁.X ∩ M₂.Y := ha ▸ rfl
  ⟨Set.mem_of_mem_inter_left haXY, Set.mem_of_mem_inter_right haXY, rfl⟩

lemma BinaryMatroid_twoSum_isRegular (ha : M₁.X ∩ M₂.Y = {a}) (hXY : M₂.X ⫗ M₁.Y)
    (hM₁ : M₁.IsRegular) (hM₂ : M₂.IsRegular) :
    (BinaryMatroid.twoSum ha hXY).fst.IsRegular := by
  obtain ⟨B₁, hB₁, hBB₁⟩ := hM₁
  obtain ⟨B₂, hB₂, hBB₂⟩ := hM₂
  obtain ⟨haX₁, haY₂, hB⟩ := BinaryMatroid_twoSum_B ha hXY
  let x' : M₁.Y.Elem → ℤ := B₁ ⟨a, haX₁⟩
  let y' : M₂.X.Elem → ℤ := (B₂ · ⟨a, haY₂⟩)
  let A₁' : Matrix (M₁.X \ {a}).Elem M₁.Y.Elem ℤ := B₁ ∘ Set.diff_subset.elem
  let A₂' : Matrix M₂.X.Elem (M₂.Y \ {a}).Elem ℤ := (B₂ · ∘ Set.diff_subset.elem)
  have hB' : (Matrix.twoSumComposition A₁' x' A₂' y').TU
  · apply Matrix_twoSumComposition_TU
    · rw [Matrix.TU_adjoin_id_left_iff] at hB₁
      apply hB₁.comp_rows
    · rw [Matrix.TU_adjoin_id_left_iff] at hB₂
      apply hB₂.comp_cols
  have hA₁ : -- cannot be inlined
    ∀ i : (M₁.X \ {a}).Elem, ∀ j : M₁.Y.Elem,
      if M₁.B (Set.diff_subset.elem i) j = 0 then A₁' i j = 0 else A₁' i j = 1 ∨ A₁' i j = -1
  · intro i j
    exact hBB₁ (Set.diff_subset.elem i) j
  have hA₂ : -- cannot be inlined
    ∀ i : M₂.X.Elem, ∀ j : (M₂.Y \ {a}).Elem,
      if M₂.B i (Set.diff_subset.elem j) = 0 then A₂' i j = 0 else A₂' i j = 1 ∨ A₂' i j = -1
  · intro i j
    exact hBB₂ i (Set.diff_subset.elem j)
  have hx' : ∀ j, if M₁.B ⟨a, haX₁⟩ j = 0 then x' j = 0 else x' j = 1 ∨ x' j = -1
  · intro j
    exact hBB₁ ⟨a, haX₁⟩ j
  have hy' : ∀ i, if M₂.B i ⟨a, haY₂⟩ = 0 then y' i = 0 else y' i = 1 ∨ y' i = -1
  · intro i
    exact hBB₂ i ⟨a, haY₂⟩
  use (Matrix.twoSumComposition A₁' x' A₂' y').toMatrixUnionUnion
  constructor
  · rw [Matrix.TU_adjoin_id_left_iff]
    exact hB'.toMatrixUnionUnion
  · intro i j
    simp only [hB, Matrix.toMatrixUnionUnion, Function.comp_apply]
    cases hi : i.toSum with
    | inl i₁ =>
      cases j.toSum with
      | inl j₁ =>
        specialize hA₁ i₁ j₁
        simp_all
      | inr j₂ =>
        simp_all
    | inr i₂ =>
      cases hj : j.toSum with
      | inl j₁ =>
        split <;> rename_i h0 <;> simp only [Matrix.of_apply, Matrix.fromBlocks_apply₂₁, mul_eq_zero, hi, hj] at h0 ⊢
        · cases h0 with
          | inl hi₂ =>
            left
            specialize hy' i₂
            simp_all [x', y', A₁', A₂']
          | inr hj₁ =>
            right
            specialize hx' j₁
            simp_all [x', y', A₁', A₂']
        · rw [not_or] at h0
          obtain ⟨hyi₂, hxj₁⟩ := h0
          specialize hy' i₂
          specialize hx' j₁
          simp only [hyi₂, ite_false] at hy'
          simp only [hxj₁, ite_false] at hx'
          cases hx' <;> cases hy' <;> simp_all
      | inr j₂ =>
        specialize hA₂ i₂ j₂
        simp_all [x', y', A₁', A₂']

end lemmas_for_2sum


section main_results

variable {M M₁ M₂ : BinaryMatroid α}

/-- Any 1-sum of regular matroids is a regular matroid. -/
theorem BinaryMatroid.Is1sum.isRegular (hM : M.Is1sumOf M₁ M₂) (hM₁ : M₁.IsRegular) (hM₂ : M₂.IsRegular) :
    M.IsRegular := by
  obtain ⟨B₁, hB₁, hBB₁⟩ := hM₁
  obtain ⟨B₂, hB₂, hBB₂⟩ := hM₂
  let B' := Matrix.oneSumComposition B₁ B₂
  have hB' : B'.TU
  · apply Matrix.fromBlocks_TU
    · rwa [Matrix.TU_adjoin_id_left_iff] at hB₁
    · rwa [Matrix.TU_adjoin_id_left_iff] at hB₂
  have hMB : M.B = (Matrix.oneSumComposition M₁.B M₂.B).toMatrixElemElem hM.X_eq hM.Y_eq
  · rewrite [hM.B_eq]
    rfl
  use B'.toMatrixElemElem hM.X_eq hM.Y_eq
  constructor
  · rw [Matrix.TU_adjoin_id_left_iff]
    exact hB'.toMatrixElemElem hM.X_eq hM.Y_eq
  · intro i j
    simp only [hMB, Matrix.oneSumComposition, Matrix.toMatrixElemElem_eq]
    cases hi : (hM.X_eq ▸ i).toSum with
    | inl i₁ =>
      cases hj : (hM.Y_eq ▸ j).toSum with
      | inl j₁ =>
        specialize hBB₁ i₁ j₁
        simp_all [B']
      | inr j₂ =>
        simp_all [B']
    | inr i₂ =>
      cases hj : (hM.Y_eq ▸ j).toSum with
      | inl j₁ =>
        simp_all [B']
      | inr j₂ =>
        specialize hBB₂ i₂ j₂
        simp_all [B']

/-- Any 2-sum of regular matroids is a regular matroid. -/
theorem BinaryMatroid.Is2sum.isRegular (hM : M.Is2sumOf M₁ M₂) (hM₁ : M₁.IsRegular) (hM₂ : M₂.IsRegular) :
    M.IsRegular := by
  obtain ⟨a, ha, hXY, rfl, -⟩ := hM
  exact BinaryMatroid_twoSum_isRegular ha hXY hM₁ hM₂

/-- Any 3-sum of regular matroids is a regular matroid. -/
theorem BinaryMatroid.Is3sum.isRegular (hM : M.Is3sumOf M₁ M₂) (hM₁ : M₁.IsRegular) (hM₂ : M₂.IsRegular) :
    M.IsRegular := by
  sorry

end main_results
