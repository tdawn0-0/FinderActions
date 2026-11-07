import { latestReleaseURL } from '../release';
import React from 'react';
import { Download } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface HeroProps {
  lang: Language;
}

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  return (
    <section className="pt-14 pb-8 md:pt-20 md:pb-10 px-4 sm:px-6 text-center">
      <div className="max-w-3xl mx-auto flex flex-col items-center">
        <h1 className="text-3xl sm:text-5xl md:text-[56px] font-semibold tracking-[-0.025em] text-white leading-[1.08] mb-7">
          {t.title}
        </h1>

        <div className="flex flex-wrap items-center justify-center gap-3 mb-4">
          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="pressable inline-flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-medium text-white bg-[#0a84ff] hover:bg-[#1b8fff]"
          >
            <Download className="w-4 h-4" />
            <span>{t.ctaDownload}</span>
          </a>

          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="pressable inline-flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium text-zinc-200 hover:text-white bg-white/6 hover:bg-white/10 border border-white/10"
          >
            <GithubIcon className="w-4 h-4" />
            <span>{t.ctaGithub}</span>
          </a>
        </div>

        <p className="text-xs font-mono text-zinc-500">
          {t.meta}
        </p>
      </div>
    </section>
  );
};
