import React, { useState } from 'react';
import { Check, Copy, Folder } from 'lucide-react';
import type { Language } from '../types';
import { translations, codeSnippets } from '../i18n';

interface ScriptShowcaseProps {
  lang: Language;
}

export const ScriptShowcase: React.FC<ScriptShowcaseProps> = ({ lang }) => {
  const t = translations[lang].how;
  const [activeIdx, setActiveIdx] = useState(0);
  const [copied, setCopied] = useState(false);

  const activeStep = t.steps[activeIdx];
  const activeCode = codeSnippets[activeStep.tab];

  const handleCopy = () => {
    navigator.clipboard.writeText(activeCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  return (
    <section id="how" className="scroll-mt-16 py-20 sm:py-28">
      <div className="container-page">
        {/* Shoji centered eyebrow + two-tone display header */}
        <div className="flex flex-col items-center text-center gap-3 mb-12 sm:mb-16">
          <p className="eyebrow">{t.eyebrow}</p>
          <h2 className="display text-[clamp(30px,3.6vw,48px)] text-[var(--color-ink)] max-w-[22ch] sm:max-w-none">
            {t.titleDark}{' '}
            <span className="text-[var(--color-ink-3)]">{t.titleMuted}</span>
          </h2>
        </div>

        {/* Shoji 01-04 left stepper + right stage */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-10 items-center">
          <div className="lg:col-span-5 flex flex-col gap-2">
            {t.steps.map((step, idx) => {
              const isActive = idx === activeIdx;
              return (
                <button
                  key={step.num}
                  type="button"
                  onClick={() => setActiveIdx(idx)}
                  className={`w-full text-left rounded-[22px] p-5 transition-all cursor-pointer ${
                    isActive
                      ? 'bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line),0_12px_32px_-16px_rgba(15,23,42,0.16)]'
                      : 'hover:bg-[var(--color-surface)]/55'
                  }`}
                >
                  <div className="flex items-baseline gap-3.5">
                    <span
                      className={`text-[12.5px] font-mono tabular-nums font-semibold ${
                        isActive ? 'text-[var(--color-accent)]' : 'text-[var(--color-ink-3)]'
                      }`}
                    >
                      {step.num}
                    </span>
                    <div className="flex-1">
                      <h3
                        className={`text-[16.5px] font-semibold tracking-tight ${
                          isActive ? 'text-[var(--color-ink)]' : 'text-[var(--color-ink-2)]'
                        }`}
                      >
                        {step.title}
                      </h3>
                      {isActive && (
                        <>
                          <p className="mt-2 text-[14.5px] leading-[1.55] text-[var(--color-ink-2)]">
                            {step.desc}
                          </p>
                          <div className="mt-3.5 h-1 w-14 rounded-full bg-[var(--color-accent)]" />
                        </>
                      )}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          {/* Right-hand code preview window */}
          <div className="lg:col-span-7 rounded-[26px] overflow-hidden bg-[var(--color-surface)] shadow-[0_0_0_1px_var(--color-line),0_24px_54px_-24px_rgba(15,23,42,0.18)]">
            <div className="h-12 px-5 border-b border-[var(--color-line)] flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-[var(--color-ink)]/15" />
                <span className="w-2.5 h-2.5 rounded-full bg-[var(--color-ink)]/15" />
                <span className="w-2.5 h-2.5 rounded-full bg-[var(--color-ink)]/15" />
                <span className="ml-2 text-[13px] font-mono font-medium text-[var(--color-ink)]">
                  {activeStep.file}
                </span>
              </div>

              <button
                type="button"
                onClick={handleCopy}
                className="h-8 px-3.5 rounded-full bg-[var(--color-paper)] shadow-[0_0_0_1px_var(--color-line)] inline-flex items-center gap-1.5 text-[12.5px] font-medium text-[var(--color-ink-2)] hover:text-[var(--color-ink)] cursor-pointer"
              >
                {copied ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-[var(--color-accent)]" />
                    <span className="text-[var(--color-accent)]">{t.copied}</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5" />
                    <span>{t.copy}</span>
                  </>
                )}
              </button>
            </div>

            <div className="p-6 overflow-x-auto bg-[#121317] text-[#f5f5f7] font-mono text-[13px] leading-[1.7] min-h-[290px] flex items-center">
              <pre className="w-full">
                <code>{activeCode}</code>
              </pre>
            </div>

            <div className="h-11 px-5 border-t border-[var(--color-line)] flex items-center justify-between text-[12px] font-mono text-[var(--color-ink-3)]">
              <span className="inline-flex items-center gap-2 truncate">
                <Folder className="w-3.5 h-3.5 shrink-0" />
                <span className="truncate">{t.pathNote}</span>
              </span>
              <span className="shrink-0 ml-3">&quot;$@&quot; · FA_CWD</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
