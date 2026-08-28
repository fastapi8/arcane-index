---
title: Cooking Mechanics
---

<script>
	import katex from 'katex';
	import 'katex/dist/katex.min.css';

	const renderMath = (source, displayMode = false) => katex.renderToString(source, {
		displayMode,
		throwOnError: true,
		strict: 'error',
		output: 'htmlAndMathml'
	});

	const equations = {
		Ei: String.raw`E_i`,
		Mi: String.raw`M_i`,
		Ci: String.raw`C_i`,
		U: String.raw`U`,
		S: String.raw`S=\sum_i C_i`,
		V: String.raw`V`,
		R: String.raw`R`,
		Q: String.raw`Q`,
		coconut: String.raw`\lfloor3.5\rfloor=3`,
		fullFloor: String.raw`\lfloor E_iM_i\rfloor`,
		pipeline: String.raw`\text{ordered ingredients}\;\longrightarrow\;\text{recipe resolution}\;\longrightarrow\;\text{energy policy}\;\longrightarrow\;\text{energy calculation}`,
		fishRaw: String.raw`E_{\mathrm{fish}} = 5 \times \mathrm{AverageStuds}`,
		tunaRange: String.raw`40.3125 \leq E_{\mathrm{Tuna}} < 40.\overline{5}`,
		uniqueCount: String.raw`U = \left|\left\{\text{distinct ingredient identities in slots 1--4}\right\}\right|`,
		alpha: String.raw`\alpha = \frac{U-1}{3}`,
		positiveContribution: String.raw`C_i = \left\lfloor E_i\left(1 + \alpha(M_i-1)\right)\right\rfloor`,
		deer: String.raw`C = \left\lfloor 45\left(1 + \frac{2}{3}(0.5)\right)\right\rfloor = \lfloor 60\rfloor = 60`,
		negativeContribution: String.raw`C_i = \left\lfloor E_iM_i\right\rfloor`,
		sum: String.raw`S = \sum_i C_i`,
		variety: String.raw`V = 1 + 0.05(U-1)`,
		finalEnergy: String.raw`E_{\mathrm{final}} = \left\lfloor S \times V \times R \times Q\right\rfloor`,
		boundary: String.raw`100 \times 1.15 = 115`,
		burger: String.raw`E_{\mathrm{Burger}} = \left\lfloor S_{\mathrm{full}} \times V \times 2.25 \times Q\right\rfloor`,
		smoothie: String.raw`E_{\mathrm{Smoothie}} = \max\left(5,\left\lfloor S \times V \times 1.5 \times Q\right\rfloor\right)`,
		duration: String.raw`D_{\mathrm{each}} = \frac{6.5\,E_{\mathrm{final}}\,Q}{N}`,
		core: String.raw`\begin{aligned}
			U &= \left|\left\{\text{identities in slots 1--4}\right\}\right|, \\
			\alpha &= \frac{U-1}{3}, \\
			C_i &= \begin{cases}
				\left\lfloor E_i\left(1+\alpha(M_i-1)\right)\right\rfloor, & M_i\geq1,\\
				\left\lfloor E_iM_i\right\rfloor, & M_i<1,
			\end{cases}\\
			S &= \sum_i C_i, \\
			V &= 1+0.05(U-1), \\
			E_{\mathrm{final}} &= \left\lfloor S\times V\times R\times Q\right\rfloor.
		\end{aligned}`
	};
</script>

Meal energy appears, at first glance, as though it should reduce to a simple
sum over the chosen ingredients, though it does not, since the game first
decides which recipe the ordered ingredients produce, then floors each
ingredient's contribution separately, and only afterward applies the variety,
recipe, and cooking-quality multipliers in turn.

The ordering matters enough that moving a single floor or multiplier to a
position that looks more natural (summing first and flooring once, say)
changes the displayed energy, sometimes by exactly one point.

Everything described as verified below is backed by a recorded in-game
observation or a regression case in the research database. It should be
noted, however, that some recipe conditions are still drawn directly from the
in-game recipe table, and the full precedence between those recipes remains,
at the time of writing, unresolved.

## Variables

The variables used throughout this page are the following:

- {@html renderMath(equations.Ei)} is its raw energy;
- {@html renderMath(equations.Mi)} is its underlying cooking multiplier;
- {@html renderMath(equations.Ci)} is its integer contribution to the meal;
- {@html renderMath(equations.U)} is the number of distinct ingredient identities in slots 1–4;
- {@html renderMath(equations.S)} is the sum of the individually floored contributions;
- {@html renderMath(equations.V)} is the variety multiplier;
- {@html renderMath(equations.R)} is the recipe multiplier;
- {@html renderMath(equations.Q)} is the cooking-quality multiplier.

In short, the calculation proceeds in the order below:

<div class="mechanics-equation">{@html renderMath(equations.pipeline, true)}</div>

It should be noted that these three stages, recipe resolution, energy
policy, and energy calculation, are kept genuinely separate by the game.
Recipe resolution decides whether the ordered ingredients constitute a
Mushroom Stew, Spaghetti, Burger, Smoothie, or an invalid meal; energy policy
then takes that result and selects which variant of the energy formula
applies, whether the normal interpolation described below or one of the
recipe exceptions covered later on this page; energy calculation, finally, is
the arithmetic itself, carried out according to whichever policy was
selected.

## Raw Energy and Identity

Every ordinary ingredient begins with a fixed raw energy *Eᵢ*, and its cooking
multiplier *Mᵢ* describes the full cooked potential that ingredient can reach.
A normal recipe, however, does not necessarily grant the ingredient all of
that potential.

Modifiers change an ingredient's energy without necessarily creating a new
identity for it. Arcane, for instance, triples the raw energy of an ordinary
non-fish ingredient; fish, however, are treated differently, and an Arcane
fish receives 1.5× instead. The verified fish-size modifiers are Small at
0.5×, Giant at 2×, and Massive at 3×, each applied to the underlying
ingredient value before the meal formula is ever reached.

Note that Arcane does **not** create a new identity for the purpose of
diversity: Boar and Arcane Boar still count as one and the same
thing. Named Giant ingredients are a different matter entirely; Seacap and
Giant Seacap are separate ingredients in the game's own bookkeeping, and are
therefore counted separately here as well.

This distinction, it should be noted, is easy to miss: "Giant" refers here to
the actual named ingredient category, not to some Arcane-enlarged version of
an ordinary one.

Something of note is that zero-energy ingredients still count toward
diversity. Samerian Ice contributes no energy whatsoever, yet it can still increase *U*
when placed in slots 1–4. The dedicated seasoning slot belongs to a separate
system entirely and does not count in this fashion.

### Fish

Fish do not, in fact, require a separate energy formula of their own. The
only unusual part is how their raw energy is determined in the first place,
which comes from fish size rather than from any fixed per-species constant:

<div class="mechanics-equation">{@html renderMath(equations.fishRaw, true)}</div>

After that raw value is established, any fish-size or Arcane modifier is
applied on top of it. Salmon and Tuna each use a cooking multiplier of 1.2;
Jellyfish uses 0.5; every other fish currently in the catalog uses 1.0.

Tuna is where matters grow somewhat stranger. Its verified contributions are
40, 43, 45, and 48 at *U* = 1, 2, 3, and 4 respectively, results that are only
consistent if its hidden raw value lies within the following interval:

<div class="mechanics-equation">{@html renderMath(equations.tunaRange, true)}</div>

Simply substituting the displayed integer 40 for that hidden value produces
one-energy errors throughout the curve. Indeed, this is exactly why the
research database stores Tuna's verified curve as an ingredient-specific
override rather than trusting the general formula. Full-potential recipes
are noted to still give Tuna its full cooked contribution of 48.

## Diversity and the First Four Slots

Only slots 1 through 4 determine diversity, as it happens:

<div class="mechanics-equation">{@html renderMath(equations.uniqueCount, true)}</div>

Slot 5 still contributes energy to the meal; it simply cannot increase *U*
itself. Whatever value slots 1–4 have already established is reused when the
fifth ingredient's own contribution is calculated.

The interpolation fraction is then given by

<div class="mechanics-equation">{@html renderMath(equations.alpha, true)}</div>

<div class="mechanics-scale" aria-label="Interpolation fraction by unique ingredient count">
	<div><span>one identity</span><strong>{@html renderMath(String.raw`U=1,\quad\alpha=0`)}</strong></div>
	<div><span>two identities</span><strong>{@html renderMath(String.raw`U=2,\quad\alpha=\frac{1}{3}`)}</strong></div>
	<div><span>three identities</span><strong>{@html renderMath(String.raw`U=3,\quad\alpha=\frac{2}{3}`)}</strong></div>
	<div><span>four identities</span><strong>{@html renderMath(String.raw`U=4,\quad\alpha=1`)}</strong></div>
</div>

Diversity, then, controls how far each positive cooking bonus is permitted to
progress toward its full potential; it is not, as one might assume, simply
another bonus tacked on after the ingredients have already been cooked.

## Per-Ingredient Calculation

### Positive Cooking Multipliers

With *U* established, each ingredient's contribution can now be calculated.
For *Mᵢ* ≥ 1, a normal recipe interpolates between raw energy and full cooked
energy according to the following:

<div class="mechanics-equation">{@html renderMath(equations.positiveContribution, true)}</div>

Each ingredient is floored individually and on its own terms; moreover, the
formula operates on the underlying multiplier directly, and it does not, as a
subtly different implementation might, interpolate toward some
already-floored solo value.

Raw Deer Meat serves as a useful illustration here. It has *E* = 45 and
*M* = 1.5, and with three unique identities present, α = 2/3, giving

<div class="mechanics-equation">{@html renderMath(equations.deer, true)}</div>

Its actual full potential is 45 × 1.5 = 67.5; if one instead stores 67 as the
target and interpolates toward that already-floored value, the resulting
calculation is simply wrong.

### Negative Cooking Multipliers

Negative cooking multipliers are considerably simpler, thankfully. When *Mᵢ*
is less than 1, the entire penalty is applied immediately, with no
interpolation at all:

<div class="mechanics-equation">{@html renderMath(equations.negativeContribution, true)}</div>

Note that this case is entirely indifferent to *U*, as Coconut demonstrates:
with *E* = 7 and *M* = 0.5, it contributes
{@html renderMath(equations.coconut)} regardless of whether the meal has one
identity or four.

### Summing the Contributions

Once every ingredient's contribution has been calculated individually, the
results are simply summed:

<div class="mechanics-equation">{@html renderMath(equations.sum, true)}</div>

It is to be noted that there is no additional floor applied at this stage,
since every *Cᵢ* is already an integer by construction; slot 5 is included in
this sum as normal, alongside the first four.

## Variety and Cooking Quality

The meal as a whole then receives a separate variety multiplier, applied
after the individual contributions have been summed:

<div class="mechanics-equation">{@html renderMath(equations.variety, true)}</div>

<div class="mechanics-scale" aria-label="Variety multiplier by unique ingredient count">
	<div><span>one identity</span><strong>{@html renderMath(String.raw`U=1,\quad V=1.00`)}</strong></div>
	<div><span>two identities</span><strong>{@html renderMath(String.raw`U=2,\quad V=1.05`)}</strong></div>
	<div><span>three identities</span><strong>{@html renderMath(String.raw`U=3,\quad V=1.10`)}</strong></div>
	<div><span>four identities</span><strong>{@html renderMath(String.raw`U=4,\quad V=1.15`)}</strong></div>
</div>

This amounts to a flat five percentage points of bonus for each additional
identity present; note that this bonus does not compound.

Cooking quality supplies the *Q* term. It begins at 1.0 and reaches 1.5 by
level 8; the dedicated seasoning slot unlocks at level 7, while the fifth
ordinary ingredient slot does not unlock until level 9.

| Cooking level | *Q* | Ingredient slots | Seasoning slot |
|---:|---:|---:|:---:|
| 1 | 1.0 | 4 | — |
| 2 | 1.1 | 4 | — |
| 3 | 1.2 | 4 | — |
| 4 | 1.3 | 4 | — |
| 5 | 1.3 | 4 | — |
| 6 | 1.4 | 4 | — |
| 7 | 1.4 | 4 | yes |
| 8 | 1.5 | 4 | yes |
| 9–10 | 1.5 | 5 | yes |

## Final Energy

Everything required for the normal energy formula has now been established.
For an ordinary recipe, where *R* = 1, this reduces to:

<div class="mechanics-equation">{@html renderMath(equations.finalEnergy, true)}</div>

It should be noted that only a single floor is applied, and it comes at the
very end. The game does **not** floor *S* × *V* first and multiply by *Q*
afterward, a subtlety that turns out to be another common source of
one-energy discrepancies for anyone reverse-engineering the formula.

### A Floating-Point Caveat

Something of note is how the game exposes ordinary IEEE-754 binary64
behavior, which is the representation Luau numbers use internally. In other
words, a value that ought to be a clean integer on paper can, in memory, sit
fractionally below that integer.

Brown Mushroom, Green Apple, Raw Bear Meat, and Raw Bird Meat together
demonstrate this rather neatly. At cooking level 1, their contributions sum to
*S* = 100, and four distinct identities give *V* = 1.15. On paper, then, one
would expect:

<div class="mechanics-equation">{@html renderMath(equations.boundary, true)}</div>

Binary64, however, evaluates this expression to a value just below 115; the
final floor therefore produces 114, which is precisely what the game displays
in practice.

Moreover, it is to be noted that there is no epsilon correction applied
anywhere in this model, and values that appear "almost" integer should not be
nudged into place. Ordinary floating-point arithmetic, combined with a plain `floor`,
reproduces the game's behavior exactly as observed.

## Recipe Exceptions

As mentioned, most recipes are governed by the normal energy policy described
above; a handful invoke a different one instead, and depending on which
recipe has been resolved, the game may force full cooked contributions,
introduce an additional multiplier, enforce a minimum value, or forgo the
calculation altogether in favor of a fixed return value.

### Full-Potential Recipes

Bread, Baguette, Spaghetti, the tested Spaghetti variants, and Breadsticks
with Sauce all skip positive interpolation entirely; every ingredient instead
receives its full cooked contribution:

<div class="mechanics-equation">{@html renderMath(equations.negativeContribution, true)}</div>

The ordinary variety multiplier still applies afterward, unchanged, and this
energy behavior has been confirmed for the named Spaghetti variants
specifically. However, it is to be noted that the exact conditions under
which several of them resolve still require further testing.

### The Burger Family

Burgers and Burger Buffet behave identically to the full-potential
recipes above, but with an additional 2.25× recipe multiplier layered on top:

<div class="mechanics-equation">{@html renderMath(equations.burger, true)}</div>

This is solved for the ordinary four-ingredient case, and all three named
variants have been confirmed to follow it. Note, however, that the fifth
ingredient slot and the seasoning slot have not been tested thoroughly enough
to state a concrete behavior for either; whether a Burger cooked with five
ingredients or with seasoning still follows this formula, or invokes some
other policy entirely, remains untested and is left for a future revision of
this page.

### Smoothies

A valid Smoothie reverts, somewhat curiously, to the normal interpolation
formula rather than the full-potential one. Samerian Ice contributes zero
energy in this context, yet still counts as an identity when placed in slots
1–4. The recipe then applies *R* = 1.5 and guarantees a minimum of 5 energy:

<div class="mechanics-equation">{@html renderMath(equations.smoothie, true)}</div>

Note that this minimum belongs to Smoothies alone and is not a general rule
of the formula. Mistake and Disgusting Smoothie are simpler
still, in that they always return exactly 5 energy, with no calculation
involved at all.

### Single-Ingredient Recipes

A meal consisting of a single ingredient does **not**, on its own, imply full
cooked potential. The ingredient must first resolve into a valid solo recipe
in its own right; the cases currently established are Pumpkin, Wheat,
Festive Cookie Dough, and fish.

Most other ingredients instead require a valid multi-ingredient recipe to
resolve at all, and it is therefore not sufficient merely to check whether the
ingredient list has a length of one.

## Status Tiers, Slot 5, and Duration

Status tiers are a matter entirely separate from energy, and Balanced Meal
tests indicate that each ingredient supplies its own tier independently;
adding either a duplicate fruit or another, distinct common fruit was not
observed to increase the tier already supplied by a different ingredient.

Slot 5 proves somewhat unusual here as well: an ingredient placed in that slot
loses its primary Recovery or Energizing contribution, yet retains its
secondary effect regardless.

Orange Swiftcap, Cursed Mushroom, and Raw Krystoros Meat each demonstrated
exactly this. In slot 5, they retained Featherfall III, Insanity III, and
Poisoned IV respectively, while losing their primary Energizing or Recovery
contribution; moving the very same ingredient back to slot 4 restored both
effects in full.

For a meal with *N* distinct status effects, each individual effect receives
a duration of

<div class="mechanics-equation">{@html renderMath(equations.duration, true)}</div>

The game divides the total duration budget evenly among the distinct effects
present, then floors each resulting displayed duration down to whole seconds.

One further point of note is that *E*<sub>final</sub> already incorporates
cooking quality, and yet the duration formula applies *Q* a second time
regardless. A Perfect meal therefore receives
6.5 × 1.5 = 9.75 seconds of total status-duration budget per point of
displayed energy. Seasoning has not been observed to alter this calculation
in any way.

## Summary

Putting all of the above together, the normal recipe formula may be stated in
full as

<div class="mechanics-summary">{@html renderMath(equations.core, true)}</div>

Under ordinary circumstances *R* = 1; Burgers use *R* = 2.25; Smoothies use
*R* = 1.5 and additionally enforce a minimum of 5. Full-potential recipes,
meanwhile, replace the positive-interpolation branch entirely with
{@html renderMath(equations.fullFloor)}.

Finally, it should be noted that any verified ingredient-specific behavior
takes priority over the general formula whenever the two disagree; Tuna
remains the clearest known example of this. The game, in the end, is
complicated enough without our having to pretend that every ingredient
behaves perfectly within a single tidy equation.
