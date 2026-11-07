import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FaqSectionProps {
  lang: Language;
}

export const FaqSection: React.FC<FaqSectionProps> = ({ lang }) => {
  const t = translations[lang].faq;
  const [openIdx, setOpenIdx] = useState<number | null>(0);


  return (
    <section id="faq" className="scroll-mt-16 py-20 sm:py-28">
      <div className="container-page grid gap-12 lg:grid-cols-[minmax(300px,380px)_minmax(0,1fr)] lg:gap-16">
        <div className="flex flex-col items-center text-center lg:sticky lg:top-28 lg:items-start lg:self-start lg:text-left gap-3">
          <p className="eyebrow">{t.eyebrow}</p>
          <h2 className="display text-[clamp(30px,3.3vw,46px)] text-[var(--color-ink)]">
            {t.title}
          </h2>
          <p className="mt-1 max-w-sm text-[15.5px] leading-relaxed text-[var(--color-ink-3)]">
            {t.note}
          </p>
          <a
            href="https://github.com/tdawn0-0/FinderActions/issues"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-1 text-[14.5px] font-medium text-[var(--color-accent)] hover:underline"
          >
            {t.githubIssues}
          </a>
        </div>

        <div className="rounded-[26px] bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line)] divide-y divide-[var(--color-line)] px-6 sm:px-8">
          {t.items.map((item, idx) => {
            const isOpen = openIdx === idx;
            return (
              <div key={item.q}>
                <button
                  type="button"
                  onClick={() => setOpenIdx(openIdx === idx ? null : idx)}
                  aria-expanded={isOpen}
                  className="w-full py-5 flex items-center justify-between text-left gap-4 cursor-pointer group"
                >
                  <span className="text-[16px] font-semibold tracking-[-0.01em] text-[var(--color-ink)]">
                    {item.q}
                  </span>
                  <span className="w-7 h-7 rounded-full bg-[var(--color-paper)] shadow-[0_0_0_1px_var(--color-line)] inline-flex items-center justify-center shrink-0">
                    <Plus
                      className={`w-4 h-4 text-[var(--color-ink-2)] transition-transform duration-200 ${
                        isOpen ? 'rotate-45 text-[var(--color-ink)]' : ''
                      }`}
                    />
                  </span>
                </button>

                {isOpen && (
                  <p className="pb-6 text-[15px] leading-[1.6] text-[var(--color-ink-2)] max-w-[64ch]">
                    {item.a}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
