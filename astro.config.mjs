// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	integrations: [
		starlight({
			title: 'Setup Manager Fansite',
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/jamf/Setup-Manager' }],
			sidebar: [
				{
					label: 'Videos',
					slug: "videos",
				},
				{
					label: 'Documentation Replica',
					autogenerate: { directory: 'docreplica' },
				},
			],
			      customCss: [
        // Relative path to your custom CSS file
        './src/styles/custom.css',
      ],
		}),
	],
});
