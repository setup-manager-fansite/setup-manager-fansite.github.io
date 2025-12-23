// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://setup-manager-fansite.github.io',
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
					label: 'Configuration Profile Reference',
					autogenerate: { directory: 'profilereference' },
					collapsed: true,
				},
				{
					label: 'Documentation Mirror',
					autogenerate: { directory: 'docmirror' },
					collapsed: true,
				},
								{
					label: 'Release Notes',
					link: "releasenotes"
				},
			],
			      customCss: [
        // Relative path to your custom CSS file
        './src/styles/custom.css',
      ],
		}),
	],
});
