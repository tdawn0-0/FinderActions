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
    <section id="faq" className="py-20 md:py-24 px-6 md:px-8 border-t border-[#ededed]/8">
      <div className="max-w-[1120px] mx-auto grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
        <div className="lg:col-span-4">
          <h2 className="text-[28px] md:text-[32px] leading-[1.15] font-medium text-[#ededed]">
            {t.title}
          </h2>
        </div>

        <div className="lg:col-span-8 divide-y divide-[#ededed]/8 border-y border-[#ededed]/8">
          {t.items.map((item, idx) => {
            const isOpen = openIdx === idx;
            return (
              <div key={item.q}>
                <button
                  type="button"
                  onClick={() => toggle(idx)}
                  aria-expanded={isOpen}
                  className="w-full py-4 flex items-center justify-between text-left gap-4 cursor-pointer group"
                >
                  <span className="text-[15px] leading-[22px] font-normal text-[#ededed] group-hover:text-white transition-colors">
                    {item.q}
                  </span>
                  <ChevronDown
                    strokeWidth={1.5}
                    className={`w-4 h-4 text-[#85858b] shrink-0 transition-transform duration-150 ${
                      isOpen ? 'rotate-180 text-[#ededed]' : ''
                    }`}
                  />
                </button>

                {isOpen && (
                  <p className="pb-5 text-[14px] leading-[22px] text-[#a1a1a6] max-w-[64ch]">
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
