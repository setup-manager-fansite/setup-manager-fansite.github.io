// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'Setup Manager Resources',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/jamf/Setup-Manager' }],
			sidebar: [
				{
					label: 'Videos',
					autogenerate: { directory: 'videos' },
				},
				{
					label: 'Documentation Replica',
					autogenerate: { directory: 'docreplica' },
				},
			],
		}),
	],
});
