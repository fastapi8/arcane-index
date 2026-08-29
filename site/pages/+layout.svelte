<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	import { afterNavigate } from '$app/navigation';

	export let data;

	const goatCounterCode = import.meta.env.VITE_GOATCOUNTER_CODE?.trim();
	const goatCounterEndpoint = /^[a-z0-9-]+$/.test(goatCounterCode ?? '')
		? `https://${goatCounterCode}.goatcounter.com/count`
		: null;

	let goatCounterLoader;

	function loadGoatCounter() {
		if (!goatCounterEndpoint) return Promise.resolve(null);
		if (window.goatcounter?.count) return Promise.resolve(window.goatcounter);
		if (goatCounterLoader) return goatCounterLoader;

		goatCounterLoader = new Promise((resolve) => {
			const script = document.createElement('script');
			script.src = 'https://gc.zgo.at/count.v5.js';
			script.async = true;
			script.crossOrigin = 'anonymous';
			script.integrity = 'sha384-atnOLvQb9t+jTSipvd75X2yginT4PjVbqDdlJAmxMm+wYElFmeR6EmLP5bYeoRVQ';
			script.dataset.goatcounter = goatCounterEndpoint;
			script.dataset.goatcounterSettings = JSON.stringify({ no_onload: true });
			script.addEventListener('load', () => resolve(window.goatcounter));
			script.addEventListener('error', () => resolve(null));
			document.head.appendChild(script);
		});

		return goatCounterLoader;
	}

	afterNavigate(({ to }) => {
		if (!to || !goatCounterEndpoint) return;

		const path = `${to.url.pathname}${to.url.search}`;
		const title = document.title;

		loadGoatCounter().then((goatcounter) => {
			goatcounter?.count({ path, title });
		});
	});
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

	:global(.mechanics-equation) {
		margin: 1.5rem 0;
		text-align: center;
		overflow-x: auto;
		overflow-y: hidden;
	}

	:global(.mechanics-summary) {
		max-width: 44rem;
		margin: 1.5rem auto;
		padding: 1rem 1.25rem;
		border: 1px solid rgb(212 212 216);
		border-radius: 0.25rem;
		text-align: center;
		overflow-x: auto;
		overflow-y: hidden;
	}

	:global(.mechanics-equation .katex-display),
	:global(.mechanics-summary .katex-display) {
		margin: 0;
	}

	:global(.mechanics-scale) {
		display: grid;
		grid-template-columns: repeat(4, minmax(0, 1fr));
		margin: 1.25rem 0 1.5rem;
		border: 1px solid rgb(212 212 216);
		border-radius: 0.25rem;
		overflow: hidden;
	}

	:global(.mechanics-scale > div) {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.35rem;
		padding: 0.85rem 0.5rem;
		text-align: center;
	}

	:global(.mechanics-scale > div + div) {
		border-left: 1px solid rgb(228 228 231);
	}

	:global(.mechanics-scale span) {
		font-size: 0.75rem;
		line-height: 1.2;
		color: rgb(113 113 122);
	}

	:global(.mechanics-scale strong) {
		font-weight: 400;
	}

	@media (max-width: 640px) {
		:global(.mechanics-scale) {
			grid-template-columns: repeat(2, minmax(0, 1fr));
		}

		:global(.mechanics-scale > div:nth-child(3)) {
			border-left: 0;
		}

		:global(.mechanics-scale > div:nth-child(n + 3)) {
			border-top: 1px solid rgb(228 228 231);
		}
	}
</style>
