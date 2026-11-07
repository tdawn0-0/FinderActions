import { latestReleaseURL } from '../release';
import React from 'react';
import { Download } from 'lucide-react';
import { GithubIcon } from './GithubIcon';
import { GlyphFolderVisual } from './GlyphFolderVisual';
import type { Language } from '../types';
import { translations } from '../i18n';

interface HeroProps {
  lang: Language;
}

export const Hero: React.FC<HeroProps> = ({ lang }) => {
  const t = translations[lang].hero;

  return (
    <section className="pt-12 pb-12 md:pt-20 md:pb-16 px-6 md:px-8">
      <div className="max-w-[1120px] mx-auto grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
        <div className="lg:col-span-7 flex flex-col items-start text-left">
          <h1 className="text-[36px] sm:text-[48px] md:text-[54px] font-medium tracking-[-0.03em] leading-[1.08] text-[#ededed] mb-5 text-balance max-w-[13.5em]">
            {t.title}
          </h1>

          <p className="text-[18px] leading-[28px] text-[#a1a1a6] max-w-[34rem] mb-8">
            {t.subhead}
          </p>

          <div className="flex flex-wrap items-center gap-3">
            <a
              href={latestReleaseURL}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-primary h-11 px-5 rounded-[8px] inline-flex items-center gap-2 text-[14px] leading-[20px] font-medium"
            >
              <Download className="w-4 h-4 shrink-0" strokeWidth={1.5} />
              <span>{t.ctaDownload}</span>
            </a>

            <a
              href="https://github.com/tdawn0-0/FinderActions"
              target="_blank"
              rel="noopener noreferrer"
              className="btn-secondary h-11 px-5 rounded-[8px] inline-flex items-center gap-2 text-[14px] leading-[20px] font-normal"
            >
              <GithubIcon className="w-4 h-4 shrink-0 text-[#85858b]" />
              <span>{t.ctaGithub}</span>
            </a>
          </div>
        </div>

        <div className="lg:col-span-5 flex items-center justify-center">
          <GlyphFolderVisual lang={lang} />
        </div>
      </div>
    </section>
  );
};
