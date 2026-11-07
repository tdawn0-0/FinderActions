import { latestReleaseURL } from '../release';
import React from 'react';
import { GithubIcon } from './GithubIcon';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FooterProps {
  lang: Language;
}

export const Footer: React.FC<FooterProps> = ({ lang }) => {
  const t = translations[lang].footer;

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <footer className="border-t border-white/8 bg-[#090a0e] py-8 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-zinc-400">
        <div className="flex items-center gap-2.5">
          <img src="/app-icon.png" alt="FinderActions" className="w-5 h-5 rounded" />
          <span className="font-medium text-zinc-200">FinderActions</span>
          <span className="text-zinc-600">·</span>
          <span className="font-mono text-zinc-500">MIT</span>
        </div>

        <div className="flex items-center gap-5">
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-white transition-colors flex items-center gap-1.5"
          >
            <GithubIcon className="w-3.5 h-3.5" />
            <span>{t.github}</span>
          </a>
          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-white transition-colors"
          >
            {t.releases}
          </a>
          <button
            type="button"
            onClick={scrollToTop}
            className="hover:text-white transition-colors cursor-pointer"
          >
            {t.backToTop}
          </button>
        </div>
      </div>
    </footer>
  );
};
