<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';

	export let data;
</script>

<EvidenceDefaultLayout {data} title="Arcane Index" builtWithEvidence={false}>
	<slot slot="content" />
</EvidenceDefaultLayout>

<style>
	:global(header a[href='/arcane-index/']) {
		align-items: center;
		gap: 0.5rem;
	}

	:global(.py-3.px-8.mb-3 > a[href='/arcane-index/']) {
		display: inline-flex;
		align-items: center;
		gap: 0.5rem;
	}

	:global(header a[href='/arcane-index/']::before),
	:global(.py-3.px-8.mb-3 > a[href='/arcane-index/']::before) {
		width: 1.25rem;
		height: 1.25rem;
		flex: none;
		content: '';
		background: url('/arcane-index/icon.svg') center / contain no-repeat;
	}

	@media (min-width: 768px) {
		:global(header a[href='/arcane-index/']) {
			display: inline-flex;
		}
	}

	/* Keep the ingredient pager stationary as searches shorten the result set. */
	:global(.ingredient-catalog > .table-container .scrollbox) {
		min-height: 630px;
	}

	:global(.ingredient-catalog table) {
		table-layout: fixed;
	}

	:global(.ingredient-catalog > .table-container .table-footer) {
		min-height: 2em;
		margin-top: 0.5em;
	}

	:global(.ingredient-catalog dialog .scrollbox) {
		min-height: calc(100dvh - 220px);
	}

	:global(.ingredient-catalog dialog .table-footer) {
		min-height: 2em;
		margin-top: 0.5em;
	}
</style>
