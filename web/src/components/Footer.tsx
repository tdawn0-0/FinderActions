import { latestReleaseURL } from '../release';
import React from 'react';
import { BrandMark } from './Navbar';
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
    <footer className="border-t border-[#ededed]/8 bg-[#0f0f10] py-8 px-6 md:px-8">
      <div className="max-w-[1120px] mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-[13px] leading-[20px] text-[#85858b]">
        <div className="flex items-center gap-2.5">
          <BrandMark />
          <span className="text-[#ededed] font-medium">FinderActions</span>
          <span>·</span>
          <span className="font-mono text-[12px]">MIT</span>
        </div>

        <div className="flex items-center gap-6">
          <a
            href="https://github.com/tdawn0-0/FinderActions"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#ededed] transition-colors"
          >
            {t.github}
          </a>
          <a
            href={latestReleaseURL}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#ededed] transition-colors"
          >
            {t.releases}
          </a>
          <button
            type="button"
            onClick={scrollToTop}
            className="hover:text-[#ededed] transition-colors cursor-pointer"
          >
            {t.backToTop}
          </button>
        </div>
      </div>
    </footer>
  );
};
