import React, { useState } from 'react';
import { Download, ToggleLeft, MousePointerClick, Terminal, Check, Copy, AlertCircle } from 'lucide-react';
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
pluginkit -m -i com.finderactions.host.FinderSync
killall Finder`;

  const handleCopyTrouble = () => {
    navigator.clipboard.writeText(troubleCmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="guide" className="py-16 md:py-24 px-4 sm:px-6 relative">
      <div className="max-w-5xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-400 font-medium mb-3">
            <Terminal className="w-3.5 h-3.5" />
            <span>{t.tag}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white tracking-tight mb-3">
            {t.title}
          </h2>
        </div>

        {/* 3 Steps Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          {/* Step 1 */}
          <div className="glass-panel rounded-2xl p-6 border border-white/10 bg-[#10131c]/80 flex flex-col justify-between hover:border-white/20 transition-all">
            <div>
              <div className="w-10 h-10 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400 mb-4">
                <Download className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-white tracking-tight mb-2">
                {t.step1Title}
              </h3>
              <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
                {t.step1Desc}
              </p>
            </div>
            <div className="mt-6">
              <a
                href="https://github.com/tdawn0-0/FinderActions/releases"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-400 hover:text-blue-300"
              >
                GitHub Releases ›
              </a>
            </div>
          </div>

          {/* Step 2 */}
          <div className="glass-panel rounded-2xl p-6 border border-white/10 bg-[#10131c]/80 flex flex-col justify-between hover:border-white/20 transition-all">
            <div>
              <div className="w-10 h-10 rounded-xl bg-purple-500/10 border border-purple-500/20 flex items-center justify-center text-purple-400 mb-4">
                <ToggleLeft className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-white tracking-tight mb-2">
                {t.step2Title}
              </h3>
              <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
                {t.step2Desc}
              </p>
            </div>
            <div className="mt-6 text-[11px] text-zinc-500 font-mono">
              Privacy & Security › Extensions
            </div>
          </div>

          {/* Step 3 */}
          <div className="glass-panel rounded-2xl p-6 border border-white/10 bg-[#10131c]/80 flex flex-col justify-between hover:border-white/20 transition-all">
            <div>
              <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 mb-4">
                <MousePointerClick className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-white tracking-tight mb-2">
                {t.step3Title}
              </h3>
              <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
                {t.step3Desc}
              </p>
            </div>
            <div className="mt-6 text-[11px] text-zinc-500 font-mono">
              Right-click file › Run action
            </div>
          </div>
        </div>

        {/* Sequoia Troubleshooting Box */}
        <div className="glass-panel rounded-2xl p-6 border border-amber-500/30 bg-[#14161f]/90">
          <div className="flex items-start justify-between gap-4 mb-3">
            <div className="flex items-center gap-2 text-amber-400">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <h4 className="text-sm font-semibold tracking-tight">
                {t.troubleTitle}
              </h4>
            </div>
            <button
              onClick={handleCopyTrouble}
              className="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-mono text-zinc-300 bg-white/5 hover:bg-white/10 border border-white/10 transition-colors"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400">Copied!</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Copy Commands</span>
                </>
              )}
            </button>
          </div>

          <p className="text-xs text-zinc-400 mb-3">
            {t.troubleDesc}
          </p>

          <div className="bg-black/60 rounded-xl p-3 border border-white/10 font-mono text-xs text-zinc-300 overflow-x-auto leading-relaxed">
            <pre><code>{troubleCmd}</code></pre>
          </div>
        </div>
      </div>
    </section>
  );
};
