import { latestReleaseURL } from '../release';
import React, { useState } from 'react';
import { Check, Copy } from 'lucide-react';
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
    <section id="guide" className="py-12 md:py-16 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto">
        <h2 className="text-xl sm:text-2xl font-semibold text-white tracking-tight mb-5">
          {t.title}
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-5">
          <div className="glass-panel rounded-2xl p-5 border border-white/8 bg-[#10121a] flex flex-col justify-between gap-4">
            <div>
              <h3 className="text-sm font-semibold text-white tracking-tight mb-1.5">
                {t.step1Title}
              </h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                {t.step1Desc}
              </p>
            </div>
            <a
              href={latestReleaseURL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs font-medium text-[#0a84ff] hover:underline w-fit"
            >
              {t.downloadLink}
            </a>
          </div>

          <div className="glass-panel rounded-2xl p-5 border border-white/8 bg-[#10121a]">
            <h3 className="text-sm font-semibold text-white tracking-tight mb-1.5">
              {t.step2Title}
            </h3>
            <p className="text-xs text-zinc-400 leading-relaxed">
              {t.step2Desc}
            </p>
          </div>

          <div className="glass-panel rounded-2xl p-5 border border-white/8 bg-[#10121a]">
            <h3 className="text-sm font-semibold text-white tracking-tight mb-1.5">
              {t.step3Title}
            </h3>
            <p className="text-xs text-zinc-400 leading-relaxed">
              {t.step3Desc}
            </p>
          </div>
        </div>

        <details className="glass-panel rounded-xl border border-white/8 bg-[#0f1118] group">
          <summary className="px-5 py-3 text-xs font-medium text-zinc-300 cursor-pointer select-none flex items-center justify-between">
            <span>{t.troubleTitle}</span>
            <span className="font-mono text-zinc-500 group-open:rotate-180 transition-transform">▾</span>
          </summary>
          <div className="px-5 pb-4 pt-1 border-t border-white/6">
            <div className="relative bg-black/50 rounded-lg p-3 border border-white/8 font-mono text-xs text-zinc-300 overflow-x-auto leading-relaxed">
              <button
                type="button"
                onClick={handleCopyTrouble}
                className="pressable absolute top-2 right-2 flex items-center gap-1 px-2 py-1 rounded text-[11px] text-zinc-300 bg-white/8 hover:bg-white/12 cursor-pointer"
              >
                {copied ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
                <span>{copied ? t.copiedCmd : t.copyCmd}</span>
              </button>
              <pre><code>{troubleCmd}</code></pre>
            </div>
          </div>
        </details>
      </div>
    </section>
  );
};
