import React from 'react';
import { Check, Minus } from 'lucide-react';
import { ShojiMark } from './Navbar';
import type { Language } from '../types';
import { translations } from '../i18n';

interface ArchitectureViewProps {
  lang: Language;
}

export const ArchitectureView: React.FC<ArchitectureViewProps> = ({ lang }) => {
  const t = translations[lang].compare;

  const renderVerdict = (v: 'yes' | 'some' | 'no', text: string, emphasize = false) => (
    <div className="flex items-start gap-2.5">
      {v === 'yes' && (
        <span className="verdict verdict-yes mt-0.5">
          <Check className="w-3 h-3" strokeWidth={2.8} />
        </span>
      )}
      {v === 'some' && (
        <span className="verdict verdict-some mt-0.5 text-[12px] font-bold leading-none">
          ~
        </span>
      )}
      {v === 'no' && (
        <span className="verdict verdict-no mt-0.5">
          <Minus className="w-3 h-3" strokeWidth={2.4} />
        </span>
      )}
      <span
        className={`text-[13.5px] leading-[1.4] ${
          emphasize ? 'font-medium text-[var(--color-ink)]' : 'text-[var(--color-ink-2)]'
        }`}
      >
        {text}
      </span>
    </div>
  );

  return (
    <section id="compare" className="scroll-mt-16 py-20 sm:py-28">
      <div className="container-page">
        <div className="flex flex-col items-center text-center gap-3 mb-12 sm:mb-14">
          <p className="eyebrow">{t.eyebrow}</p>
          <h2 className="display text-[clamp(30px,3.6vw,48px)] text-[var(--color-ink)]">
            {t.titleDark}
            <br />
            <span className="text-[var(--color-ink-3)]">{t.titleMuted}</span>
          </h2>
          <p className="mt-2 max-w-[42rem] text-balance text-[16.5px] leading-relaxed text-[var(--color-ink-2)]">
            {t.lede}
          </p>
        </div>

        <div className="rounded-[26px] overflow-hidden bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line)]">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] border-collapse text-left">
              <thead>
                <tr className="border-b border-[var(--color-line)] text-[13.5px] font-semibold text-[var(--color-ink-2)]">
                  <th className="py-4 px-6 w-[23%] font-medium text-[var(--color-ink-3)]">
                    {t.headers[0]}
                  </th>
                  <th className="py-4 px-5 w-[22%] bg-[var(--color-accent)]/4 text-[var(--color-ink)]">
                    <span className="inline-flex items-center gap-2">
                      <ShojiMark className="w-4 h-4 text-[var(--color-ink)]" />
                      <span>{t.headers[1]}</span>
                    </span>
                  </th>
                  <th className="py-4 px-5 w-[18.5%]">{t.headers[2]}</th>
                  <th className="py-4 px-5 w-[18.5%]">{t.headers[3]}</th>
                  <th className="py-4 px-5 w-[18%]">{t.headers[4]}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[var(--color-line)]">
                {t.rows.map((row) => (
                  <tr key={row.topic} className="align-top">
                    <td className="py-4 px-6 text-[14px] font-medium text-[var(--color-ink)]">
                      {row.topic}
                    </td>
                    <td className="py-4 px-5 bg-[var(--color-accent)]/4">
                      {renderVerdict(row.fa.v, row.fa.t, true)}
                    </td>
                    <td className="py-4 px-5">{renderVerdict(row.mac.v, row.mac.t)}</td>
                    <td className="py-4 px-5">{renderVerdict(row.sbx.v, row.sbx.t)}</td>
                    <td className="py-4 px-5">{renderVerdict(row.elec.v, row.elec.t)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <p className="mt-5 text-center text-[13px] text-[var(--color-ink-3)]">
          {t.footnote}
        </p>
      </div>
    </section>
  );
};
