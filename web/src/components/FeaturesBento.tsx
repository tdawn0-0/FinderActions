import React from 'react';
import { 
  Cpu, 
  Filter, 
  TerminalSquare, 
  ShieldCheck, 
  GitBranch, 
  Lock, 
  Sparkles,
  Zap
} from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FeaturesBentoProps {
  lang: Language;
}

export const FeaturesBento: React.FC<FeaturesBentoProps> = ({ lang }) => {
  const t = translations[lang].features;

  const getIcon = (id: string) => {
    switch (id) {
      case 'lightweight':
        return <Cpu className="w-5 h-5 text-blue-400" />;
      case 'showWhen':
        return <Filter className="w-5 h-5 text-amber-400" />;
      case 'launchers':
        return <TerminalSquare className="w-5 h-5 text-emerald-400" />;
      case 'safeArgv':
        return <ShieldCheck className="w-5 h-5 text-indigo-400" />;
      case 'git':
        return <GitBranch className="w-5 h-5 text-purple-400" />;
      case 'privacy':
        return <Lock className="w-5 h-5 text-teal-400" />;
      default:
        return <Sparkles className="w-5 h-5 text-blue-400" />;
    }
  };

  return (
    <section id="features" className="py-16 md:py-24 px-4 sm:px-6 relative">
      <div className="max-w-5xl mx-auto">
        {/* Section Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-xs text-blue-400 font-medium mb-3">
            <Zap className="w-3.5 h-3.5" />
            <span>{t.tag}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white tracking-tight mb-3">
            {t.title}
          </h2>
          <p className="text-sm sm:text-base text-zinc-400 max-w-xl mx-auto">
            {t.subtitle}
          </p>
        </div>

        {/* Bento Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {t.bento.map((item) => (
            <div
              key={item.id}
              className="glass-panel rounded-2xl p-6 flex flex-col justify-between border border-white/10 hover:border-white/20 transition-all duration-300 hover:-translate-y-1 group bg-[#11131c]/70 hover:shadow-2xl hover:shadow-blue-500/5"
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="p-2 rounded-xl bg-white/5 border border-white/10 group-hover:scale-110 transition-transform">
                    {getIcon(item.id)}
                  </div>
                  <span className="text-[11px] font-mono font-medium px-2 py-0.5 rounded-full bg-white/10 text-zinc-300 border border-white/10">
                    {item.badge}
                  </span>
                </div>
                <h3 className="text-base sm:text-lg font-semibold text-white tracking-tight mb-2">
                  {item.title}
                </h3>
                <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed font-normal">
                  {item.desc}
                </p>
              </div>

              <div className="mt-6 pt-4 border-t border-white/5 flex items-center justify-between text-[11px] text-zinc-500 font-mono">
                <span>macOS 15 Native</span>
                <span className="text-blue-400/80 group-hover:text-blue-300 transition-colors">FinderActions Core ›</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
