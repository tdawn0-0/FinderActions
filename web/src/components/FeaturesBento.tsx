import React from 'react';
import { Copy, Terminal, Code2, FileCode } from 'lucide-react';
import type { Language } from '../types';
import { translations } from '../i18n';

interface FeaturesBentoProps {
  lang: Language;
}

export const FeaturesBento: React.FC<FeaturesBentoProps> = ({ lang }) => {
  const t = translations[lang].features;

  const getIcon = (id: string) => {
    switch (id) {
      case 'paths':
        return <Copy className="w-4 h-4 text-zinc-300" />;
      case 'terminals':
        return <Terminal className="w-4 h-4 text-zinc-300" />;
      case 'editors':
        return <Code2 className="w-4 h-4 text-zinc-300" />;
      default:
        return <FileCode className="w-4 h-4 text-zinc-300" />;
    }
  };

  return (
    <section id="features" className="py-12 md:py-16 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-px rounded-2xl overflow-hidden bg-white/8 border border-white/8">
        {t.items.map((item) => (
          <div
            key={item.id}
            className="bg-[#0e1016] p-6 flex flex-col gap-3"
          >
            <div className="w-8 h-8 rounded-lg bg-white/5 border border-white/8 flex items-center justify-center">
              {getIcon(item.id)}
            </div>
            <h2 className="text-sm font-semibold text-white tracking-tight">
              {item.title}
            </h2>
            <p className="text-xs text-zinc-400 leading-relaxed">
              {item.desc}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
};
