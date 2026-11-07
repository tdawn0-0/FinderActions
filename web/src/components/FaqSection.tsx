import React, { useState } from 'react';
import { ChevronDown } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FaqSectionProps {
  lang: Language;
}

export const FaqSection: React.FC<FaqSectionProps> = ({ lang }) => {
  const t = translations[lang].faq;
  const [openIdx, setOpenIdx] = useState<number | null>(0);

  const toggle = (idx: number) => {
    setOpenIdx(openIdx === idx ? null : idx);
  };

  return (
    <section id="faq" className="py-12 md:py-16 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-xl sm:text-2xl font-semibold text-white tracking-tight mb-5">
          {t.title}
        </h2>

        <div className="rounded-2xl overflow-hidden border border-white/8 bg-[#0f1118] divide-y divide-white/6">
          {t.items.map((item, idx) => {
            const isOpen = openIdx === idx;
            return (
              <div key={item.q}>
                <button
                  type="button"
                  onClick={() => toggle(idx)}
                  aria-expanded={isOpen}
                  className="w-full px-5 py-3.5 flex items-center justify-between text-left hover:bg-white/4 transition-colors gap-4 cursor-pointer"
                >
                  <span className="text-sm font-medium text-zinc-100">
                    {item.q}
                  </span>
                  <ChevronDown
                    className={`w-4 h-4 text-zinc-400 shrink-0 transition-transform duration-150 ${
                      isOpen ? 'rotate-180 text-white' : ''
                    }`}
                  />
                </button>

                {isOpen && (
                  <div className="px-5 pb-4 text-xs sm:text-sm text-zinc-400 leading-relaxed">
                    {item.a}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
};
