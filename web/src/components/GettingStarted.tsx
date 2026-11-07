import { latestReleaseURL } from '../release';
import React, { useState } from 'react';
import { Check, Copy, ArrowUpRight } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface GettingStartedProps {
  lang: Language;
}

export const GettingStarted: React.FC<GettingStartedProps> = ({ lang }) => {
  const t = translations[lang].guide;
  const [copied, setCopied] = useState(false);

  const troubleCmd = `pluginkit -a "/Applications/FinderActions.app/Contents/PlugIns/FAFinderSync.appex"
pluginkit -e use -i com.finderactions.host.FinderSync
killall Finder`;

  const handleCopyTrouble = () => {
    navigator.clipboard.writeText(troubleCmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  return (
    <section id="guide" className="py-20 md:py-24 px-6 md:px-8 border-t border-[#ededed]/8">
      <div className="max-w-[1120px] mx-auto">
        <h2 className="text-[28px] md:text-[32px] leading-[1.15] font-medium text-[#ededed] mb-10">
          {t.title}
        </h2>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
          <div className="lg:col-span-6 flex flex-col divide-y divide-[#ededed]/8 border-y border-[#ededed]/8">
            {t.steps.map((step, idx) => (
              <div key={step.num} className="py-5 flex items-start gap-5">
                <span className="text-[12px] leading-[22px] font-mono tabular-nums text-[#85858b] w-6 shrink-0">
                  {step.num}
                </span>
                <div className="flex flex-col gap-1.5">
                  <h3 className="text-[15px] leading-[22px] font-medium text-[#ededed]">
                    {step.title}
                  </h3>
                  <p className="text-[14px] leading-[22px] text-[#a1a1a6]">
                    {step.desc}
                  </p>
                  {idx === 0 && (
                    <a
                      href={latestReleaseURL}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-1 inline-flex items-center gap-1.5 text-[13px] leading-[20px] text-[#ededed] hover:text-[#0a84ff] transition-colors w-fit"
                    >
                      <span>{t.downloadLink}</span>
                      <ArrowUpRight className="w-4 h-4 text-[#85858b]" strokeWidth={1.5} />
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>

          <div className="lg:col-span-6 rounded-[16px] overflow-hidden bg-[#19191b] border border-[#ededed]/8">
            <div className="h-12 px-4 border-b border-[#ededed]/8 flex items-center justify-between gap-3">
              <span className="text-[13px] leading-[20px] text-[#a1a1a6]">
                {t.troubleTitle}
              </span>
              <button
                type="button"
                onClick={handleCopyTrouble}
                className="btn-secondary h-8 px-3 rounded-[8px] inline-flex items-center gap-2 text-[12px] leading-[16px] shrink-0 cursor-pointer"
              >
                {copied ? (
                  <>
                    <Check className="w-4 h-4 text-[#4cc38a] shrink-0" strokeWidth={1.5} />
                    <span className="text-[#4cc38a]">{t.copiedCmd}</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-4 h-4 text-[#85858b] shrink-0" strokeWidth={1.5} />
                    <span>{t.copyCmd}</span>
                  </>
                )}
              </button>
            </div>
            <div className="p-5 bg-[#0f0f10] font-mono text-[12px] leading-[22px] text-[#ededed] overflow-x-auto">
              <pre>
                <code>{troubleCmd}</code>
              </pre>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
