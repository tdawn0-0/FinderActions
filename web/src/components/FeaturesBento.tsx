import React from 'react';
import { Check, ArrowRight, Package } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FeaturesBentoProps {
  lang: Language;
}

export const FeaturesBento: React.FC<FeaturesBentoProps> = ({ lang }) => {
  const t = translations[lang].features;

  const renderArt = (id: string) => {
    switch (id) {
      case 'paths':
        return (
          <div className="fit-art">
            <div className="rounded-full bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line)] px-3.5 py-2 font-mono text-[12.5px] text-[var(--color-ink)] flex items-center gap-2.5">
              <span className="truncate max-w-[160px]">/Users/dev/hero.png</span>
              <span className="inline-flex items-center gap-1 rounded-full bg-[var(--color-accent)] text-white px-2 py-0.5 text-[11px] font-sans font-semibold">
                <Check className="w-3 h-3" strokeWidth={2.5} />
                pbcopy
              </span>
            </div>
          </div>
        );

      case 'terminals':
        return (
          <div className="fit-art flex-wrap content-center px-5 gap-2">
            {['Ghostty', 'iTerm2', 'Warp', 'Kitty', 'Alacritty', 'Terminal'].map((name, i) => (
              <span
                key={name}
                className={
                  i === 0
                    ? 'rounded-full bg-[var(--color-accent)] text-white px-3 py-1 text-[13px] font-semibold shadow-sm'
                    : 'fit-pill'
                }
              >
                {name}
              </span>
            ))}
          </div>
        );

      case 'editors':
        return (
          <div className="fit-art flex-wrap content-center px-5 gap-2">
            {['Cursor', 'VS Code', 'Zed', 'Xcode', 'Sublime', 'JetBrains'].map((name, i) => (
              <span
                key={name}
                className={
                  i === 0
                    ? 'rounded-full bg-[var(--color-ink)] text-[var(--color-paper)] px-3 py-1 text-[13px] font-semibold'
                    : 'fit-pill'
                }
              >
                {name}
              </span>
            ))}
          </div>
        );

      case 'argv':
        return (
          <div className="fit-art">
            <div className="inline-flex items-center gap-1.5 p-2 rounded-[14px] shadow-[0_0_0_2px_var(--color-accent)]">
              <kbd className="fit-keycap">&quot;$@&quot;</kbd>
              <kbd className="fit-keycap">FA_CWD</kbd>
              <kbd className="fit-keycap">0</kbd>
            </div>
          </div>
        );

      case 'packages':
        return (
          <div className="fit-art gap-2.5">
            <div className="rounded-[12px] bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line)] px-3 py-2 flex items-center gap-2 text-[12.5px] font-mono text-[var(--color-ink)]">
              <Package className="w-4 h-4 text-[var(--color-accent)]" strokeWidth={1.8} />
              <span>.faaction</span>
            </div>
            <ArrowRight className="w-4 h-4 text-[var(--color-ink-3)]" />
            <span className="sale-tag">Disabled draft</span>
          </div>
        );

      default:
        return (
          <div className="fit-art gap-3">
            <div className="flex flex-col gap-1.5">
              <span className="fit-pill">English</span>
              <span className="fit-pill">简体中文</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-[74px] h-[54px] rounded-[9px] bg-white shadow-[0_0_0_1px_rgba(15,23,42,0.1)] p-1.5 flex gap-1">
                <span className="flex-1 rounded-[3px] bg-[#0a7cff]" />
                <span className="flex-1 rounded-[3px] bg-[#e4e4e9]" />
              </div>
              <div className="w-[74px] h-[54px] rounded-[9px] bg-[#1b1b20] shadow-[0_0_0_1px_rgba(255,255,255,0.12)] p-1.5 flex gap-1">
                <span className="flex-1 rounded-[3px] bg-[#2b8fff]" />
                <span className="flex-1 rounded-[3px] bg-[#3a3a42]" />
              </div>
            </div>
          </div>
        );
    }
  };

  return (
    <section id="features" className="scroll-mt-16 py-20 sm:py-28">
      <div className="container-page">
        <div className="mx-auto max-w-[720px] flex flex-col items-center text-center gap-3 mb-12 sm:mb-14">
          <p className="eyebrow">{t.eyebrow}</p>
          <h2 className="display text-[clamp(30px,3.6vw,48px)] text-[var(--color-ink)]">
            {t.titleDark}
            <br className="hidden sm:block" />{' '}
            <span className="text-[var(--color-ink-3)]">{t.titleMuted}</span>
          </h2>
        </div>

        <ul className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {t.cards.map((card) => (
            <li key={card.id} className="fit-card">
              {renderArt(card.id)}
              <h3 className="mt-5 mx-3 text-[17px] font-semibold tracking-[-0.015em] text-[var(--color-ink)]">
                {card.title}
              </h3>
              <p className="mt-2 mx-3 text-[15px] leading-[1.55] text-[var(--color-ink-2)]">
                {card.body}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
};
